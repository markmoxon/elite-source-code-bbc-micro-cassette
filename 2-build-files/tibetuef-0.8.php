<?php

/*
 *  Quadbike 2
 *  Copyright (C) 2024 'Diminished'

 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

  // PHP >=7, reduce stupidity
  declare (strict_types=1);
  
  define ("APPNAME",                  "tibetuef.php");
  define ("TIBETUEF_VERSION",         "0.8");
  //define ("TIBET_VERSION_STG",        "0.4");
  define ("TIBET_MAJOR_VERSION",      "0");

  define ("TBT_E_OK",                 0);
  define ("TBT_E_USAGE",              1);
  define ("TBT_E_LOAD",               2);
  define ("TBT_E_IPFN_MATCHES_OPFN",  3);
  define ("TBT_E_PARSE_VERSION",      4);
  define ("TBT_E_BAD_VERSION",        5);
  define ("TBT_E_PARSE_BAD_LINE",     6);
  define ("TBT_E_PARSE_SILENCE",      7);
  define ("TBT_E_BAD_SILENCE",        8);
  define ("TBT_E_PARSE_LEADER",       9);
  define ("TBT_E_BAD_LEADER",         10);
  define ("TBT_E_PARSE_DATA",         11);
  define ("TBT_E_BAD_PHASE",          12);
  define ("TBT_E_PARSE_CYCLES",       13);
  define ("TBT_E_BUG",                14);
  define ("TBT_E_WRITE_FILE",         15);
  define ("TBT_E_PARSE_HINT",         16);
  define ("TBT_E_BAD_FRAMING",        17);
  define ("TBT_E_PARSE_DUP_VERSION",  18);
  define ("TBT_E_BAD_INT",            19);
  define ("TBT_E_BAD_FLOAT",          20);
  define ("TBT_E_GZIP",               21);
  // 0.7: handle void chunks
  define ("TBT_E_ZL_CHUNK",           22);
  // 0.8: major version mismatch
  define ("TBT_E_INCOMPATIBLE",       23);
 
  define ("STATE_VERSION", 0);
  define ("STATE_IDLE",    1);
  define ("STATE_CYCLES",  2);
  
  class Span {
    var $linenum;
    var $span_ix;
  }
  
  class TimeHint extends Span {
    var $timestamp;
  }
  
  class ParsedTibet {
    var $version;
    var $spans;
    function __construct() {
      $this->spans   = array();
      $this->version = "";
    }
  }
  
  class TibetSilence extends Span {
    var $secs;
  }
  
  class TibetLeader extends Span {
    var $cycles;
  }
  
  class DataFraming extends Span {
    var $framelen;    // 7 or 8: FIXME: rename to wordlen
    var $parity; // string; "N", "O", "E"
    var $stops;  // 1 or 2
    //var $autodetected;
    function to_string() : string {
      return "$this->framelen$this->parity$this->stops";
    }
    function __construct() {
      // defaults
      $this->framelen = 8;
      $this->parity   = "N";
      $this->stops    = 1;
    }
  }
  
  class BaudRate extends Span {
    var $rate;
    function to_string() : string {
      return "$this->rate";
    }
    function __construct() {
      // default
      $this->rate = 1200;
    }
  }
  
  class TibetData extends Span {
    var $squawk;
    var $cycles; // array
    var $bits;
    var $framing; // DataFraming
    function __construct() {
      $this->cycles = array(); // TibetCycles
      $this->bits   = array(); // also TibetCycles ...
      $this->squawk = 0;
    }
  }
  
  class TibetCycle extends Span {
    var $value;
  }
  
  class DummyByte extends Span {
    var $pre_leader_cycs;
    var $post_leader_cycs;
    var $byte_value;
  }
  
  $e = tbt_main ($_SERVER['argc'], $_SERVER['argv']);
  if (TBT_E_USAGE == $e) { usage($_SERVER['argv'][0]); }
  return $e;
  
  die();
  
  function tbt_main ($argc, $argv) : int {
  
    print "\ntibetuef.php ".TIBETUEF_VERSION."\n\n";
    
    $insert_timestamps = 0;
    
    $use_chunk_102 = 0;
    //$use_chunk_102b = 0;
    $use_chunk_104 = 0;
    $use_chunk_114 = 0;
    // 0.8: option to use &112 for silence
    $use_chunk_112_for_silence = 0;
    $have_nz = 0;
    $have_no_117 = 0; // 0.6
    
    if ($argc < 3) { // PHP filename, ipfn, opfn
      return TBT_E_USAGE;
    }
    
    $chunk_change_count = 0;
    
    // -2 for ipfn, opfn
    for ($i=1, $dupe=0; $i < ($argc - 2); $i++) {
      $a = $argv[$i];
      if ($a[0] != "+") { break; }
      //if (CLI_STATE_IDLE == $state) {
      //if ($a == "+f") {
      //  if ($autodetect_framings) { return TBT_E_USAGE; } // dup
      //  $autodetect_framings = 1;
      //} else
      if ($a == "+t") {
        if ($insert_timestamps) { $dupe = 1; } // dup
        $insert_timestamps = 1;
      } else if ($a == "+102") {
        if ($use_chunk_102) { $dupe = 1; }
        $use_chunk_102 = 1;
        $chunk_change_count++;
      //} else if ($a == "+102b") {
      //  if ($use_chunk_102b) { $dupe = 1; }
      //  $use_chunk_102b = 1;
      //  $chunk_change_count++;
      } else if ($a == "+104") {
        if ($use_chunk_104) { $dupe = 1; }
        $use_chunk_104 = 1;
        $chunk_change_count++;
      } else if ($a == "+114") {
        if ($use_chunk_114) { $dupe = 1; }
        $use_chunk_114 = 1;
        $chunk_change_count++;
      } else if ($a == "+112") { // 0.8
        if ($use_chunk_112_for_silence) { $dupe = 1; }
        $use_chunk_112_for_silence = 1;
      } else if ($a == "+nz") {
        if ($have_nz) { $dupe = 1; }
        $have_nz = 1;
      } else if ($a == "+no-117") { // 0.6
        if ($have_no_117) { $dupe = 1; }
        $have_no_117 = 1;
      } else {
        print "E: Unknown option $a\n\n";
        return TBT_E_USAGE;
      }
      
      if ($dupe) {
        print "E: Duplicate option $a specified.\n\n";
        return TBT_E_USAGE;
      }
      
    }
    
    if ($chunk_change_count > 1) {
      print "E: Can only supply one of +102, +104 and +114.\n\n";
      return TBT_E_USAGE;
    }
    
    $ipfn = $argv[$argc - 2];
    $opfn = $argv[$argc - 1];
    
    print "Input file:  $ipfn\n";
    print "Output file: $opfn\n";
    if ($insert_timestamps) {
      print "Inserting &120 chunks for /time hints.\n";
    }
    
    // 0.8
    if ($use_chunk_112_for_silence) {
      print "Using &112 for silence instead of &116.\n";
    }
    
    //$chunk_102_interpretation = -1;
    
    $chunk_to_use_for_data = 0x100;
    if ($use_chunk_102) { // || $use_chunk_102b) {
      $chunk_to_use_for_data = 0x102;
      //$chunk_102_interpretation = $use_chunk_102b;
    } else if ($use_chunk_104) {
      $chunk_to_use_for_data = 0x104;
    } else if ($use_chunk_114) {
      $chunk_to_use_for_data = 0x114;
    }
    if ($chunk_change_count > 0) {
      print "Using chunk type &".sprintf("%x", $chunk_to_use_for_data)." for data.\n";
    }
    
    if ($have_nz) {
      print "Will not compress output UEF file.\n";
    }
    
    //if ($autodetect_framings) {
    //  print "Autodetecting framings.\n";
    //} else {
    //  print "Taking framings from TIBET file.\n";
    //}
    
    print "\n";
    
    if ($ipfn == $opfn) {
      print "E: Input and output filenames cannot match.\n";
      return TBT_E_IPFN_MATCHES_OPFN;
    }
    
    if (FALSE === ($ip = file_get_contents($ipfn))) {
      print "E: Could not load file: $ipfn\n";
      return TBT_E_LOAD;
    }
    
    $len = strlen($ip);
    
    print "Loaded $len bytes.\n";
    
    // try gzdecode
    $ip_unz = @gzdecode($ip);
    if (FALSE === $ip_unz) {
      print "Input TIBET was uncompressed.\n";
    } else {
      print "Decompressed input TIBET: ".strlen($ip)." -> ".strlen($ip_unz)." bytes.\n";
      $ip = $ip_unz;
    }
    
    $tbt = new ParsedTibet;
    $e = tbt_process ($ip, ($insert_timestamps == 1), $tbt); // tbt populated
    if (TBT_E_OK != $e) { return $e; }
    
    $e = cycles_to_bits ($tbt);   // tbt modified
    if (TBT_E_OK != $e) { return $e; }
    
    //if ($autodetect_framings) {
      // override framings that may have been read from the TIBET file earlier
      //$e = autopopulate_framings($tbt); // tbt modified
      //if (TBT_E_OK != $e) { return $e; }
    //} else {
    //$e = populate_framings_from_tibet ($tbt); // tbt modified
    //if (TBT_E_OK != $e) { return $e; }
    //}
    
    // 0.4
    $e = spans_fix_up_long_leader($tbt);
    if (TBT_E_OK != $e) { return $e; }
    
    // 0.4
    $e = spans_detect_and_convert_dummy_bits($tbt);
    if (TBT_E_OK != $e) { return $e; }
    
    $uef = "";
    $msg = "";
    $e = build_uef ($tbt,
                    $chunk_to_use_for_data,
                    $use_chunk_112_for_silence, // 0.8
                    //$chunk_102_interpretation,
                    $have_no_117, // 0.6
                    $uef,
                    $msg);
    if (TBT_E_OK != $e) { return $e; }
    print "\nChunks: (type-len)\n";
    print_chunk_messages($msg);
    print "\n";
    
    if ( ! $have_nz ) {
      $uef_z = gzencode($uef, 9, FORCE_GZIP);
      if (FALSE === $uef_z) {
        print "E: Could not compress output UEF.\n";
        return TBT_E_GZIP;
      }
      print "Compressed output UEF: ".strlen($uef)." -> ".strlen($uef_z)." bytes.\n";
      $uef = $uef_z;
    }
    
    if (FALSE === file_put_contents($opfn, $uef)) {
      print "E: Could not write file: $opfn\n";
      return TBT_E_WRITE_FILE;
    }
    
    return TBT_E_OK;
    
  }
  
  
  // 0.4
  function spans_fix_up_long_leader (ParsedTibet &$tbt) : int {
    $spans_new = array();
    foreach ($tbt->spans as $k=>$span) {
      if ((get_class($span) != "TibetLeader") || ($span->cycles <= 0xffff)) {
        $spans_new[] = $span;
        continue;
      }
      for ($rem = $span->cycles; $rem > 0; $rem -= 0xffff) {
        $num_cycs = $rem;
        if ($num_cycs > 0xffff) {
          $num_cycs = 0xffff;
        }
        $new_span = new TibetLeader;
        $new_span->linenum = $span->linenum;
        $new_span->span_ix = $span->span_ix; // preserve this
        $new_span->cycles = $num_cycs;
        $spans_new[] = $new_span;
        //~ print "M: L$span->linenum, span $span->span_ix: Leader: $num_cycs cycs\n";
      }
    }
    $tbt->spans = $spans_new;
//foreach ($tbt->spans as $k=>$v) { if ("TibetLeader"==get_class($v)) { print "L: $v->cycles\n"; } }
    return TBT_E_OK;
  }
  
  
  function print_chunk_messages ($msg) {
    print wordwrap($msg);
  }
  
  
  function cycles_to_bits (ParsedTibet &$tbt) : int {
  
    $current_baud = 1200;
    
    foreach ($tbt->spans as $sn => $span) {
    
      if (gettype($span) != "object") {
        print "B: cycles_to_bits: Bad span type: \"".gettype($span)."\"\n";
        return TBT_E_BUG;
      }
      
      $type = get_class($span);
      
      if ("BaudRate" == $type) {
        print "span #$span->span_ix: Baud rate change: $current_baud -> $span->rate\n";
        $current_baud = $span->rate;
      }
      
      if ("TibetData" != $type) {
        continue;
      }
    
      //print count($tbd->cycles)." cycles in span\n";
      
      $span->bits = array();
      $i=0;
      
//print_r($span); die();

      $bitlen = 2;
      if ($current_baud == 300) {
        $bitlen = 8;
      }
      
      $num_atoms = count($span->cycles);
      
      //for ($i=0; $i < (count($span->cycles) - 1); $i+=2) {
      for ($i=0; $i < ($num_atoms - ($bitlen - 1)); $i += $bitlen) {
        //$atoms = array();
        $ln = $span->cycles[$i]->linenum;
        $zeros = 0;
        $ones = 0;
        for ($j=0; ($j < $bitlen) && (($i + $j) < $num_atoms); $j++) {
          //$atoms[$j] = $span->cycles[$i + $j];
          if ($span->cycles[$i + $j]->value) {
            $ones++;
          } else {
            $zeros++;
          }
        }
        if ($j != $bitlen) {
          print "W: cycles_to_bits: line $ln, span #$span->span_ix: Partial bit\n";
          $atom = $span->cycles[$i]; // partial bit: use the first atom's value
        } else {
          /*
          for ($j=0; $j < $bitlen; $j++) {
            if ($span->cycles[$i + $j]->value) {
              $ones++;
            } else {
              $zeros++;
            }
          }
          */
          if (($ones == $bitlen) || ($zeros == $bitlen)) {
            // unanimous
            $atom = $span->cycles[$i];
          } else {
            // bad bit
            print "W: cycles_to_bits: line $ln, span #$span->span_ix: Fuzzy bit\n";
            // skip one atom and resynchronise
            $i -= ($bitlen - 1);
            continue;
          }
          
          // this is the old code that allowed voting on
          // 300 baud bits; it now violates the TIBET
          // specification on decode, so it's been replaced
          // with the simple skip-one-atom-and-resync logic from the spec
          /*
          } else {
            print "W: cycles_to_bits: line $ln, span #$span->span_ix: Fuzzy bit\n";
            if ($ones > $zeros) {
              // find first one
              for ($j=0; $j < $bitlen; $j++) {
                if ($span->cycles[$i + $j]->value) {
                  $atom = $span->cycles[$i];
                }
              }
            } else if ($ones < $zeros) {
              // find first zero
              for ($j=0; $j < $bitlen; $j++) {
                if ( ! $span->cycles[$i + $j]->value ) {
                  $atom = $span->cycles[$i];
                }
              }
            } else {
              // it's a tie, just use first atom
              $atom = $span->cycles[$i];
            }
          }
          */
          
        }
        
        // at this point we should have an atom
        //$a = $span->cycles[$i]->value;
        //$b = $span->cycles[$i+1]->value;

        /*
        if ($a != $b) {
          print "W: cycles_to_bits: L$ln, span #$span->span_ix: Cycle pair mismatch\n";
          // skip one and resynchronise
          $i--;
          continue;
        }
        $span->bits[] = $span->cycles[$i];
        */
        
        $span->bits[] = $atom;
        
      }
      
      //print count($bits)." bits in span\n";
    
    } // next span
    
    return TBT_E_OK;
    
  }
  
  
  function populate_framings_from_tibet (ParsedTibet &$tbt) : int {
    // use "framing ..." lines to set framings on subsequent data spans
    $framing = new DataFraming; // 8N1 default
    foreach ($tbt->spans as $sn => $span) {
      if (gettype($span) != "object") {
        print "B: populate_framings_from_tibet: Bad span type: \"".gettype($span)."\"\n";
        return TBT_E_BUG;
      }
      $type = get_class($span);
      if ("TibetData" == $type) {
        // note that this means the framing field on the data span
        // is itself a span, with a span_ix and a line number, which
        // will be the originating span where this framing was programmed.
        $tbt->spans[$sn]->framing = $framing;
      } else if ("DataFraming" == $type) {
        $framing = $span;
      }
    }
    return TBT_E_OK;
  }
  
/*
  function autopopulate_framings (ParsedTibet &$tbt) : int {
  
    // default to 8N1 framing, since BASIC always needs this to load
    $prev_framing = new DataFraming;
  
    foreach ($tbt->spans as $sn => $span) {
    
      if (gettype($span) != "object") {
        print "B: autopopulate_framings: Bad span type: \"".gettype($span)."\"\n";
        return TBT_E_BUG;
      }
      
      $type = get_class($span);
      
      if ("TibetData" != $type) {
        continue;
      }
      
      if ($span->squawk) {
        continue;
      }
      
      // need to identify framing format
      
      // "For the BBC/Electron, the following formats may be encountered:
      //  7E1, 7E2, 7O1, 7O2, 8E1, 8N2, 8O1.
      //  Format 8N1 would produce the same output as chunk &0100."
      
      // 7E1/7O1: 0xxxxxxxP1  }
      // 8N1:     0xxxxxxxx1  } "short"
      //                   ^ short_stops_score counts these
      
      // 7E2/7O2: 0xxxxxxxP11 } "long"
      // 8N2:     0xxxxxxxx11 }
      // 8E1/8O1: 0xxxxxxxxP1 }
      //                    ^ long_stops_score counts these
      //                   ^ double_stop_score counts these
      
      $bits = $span->bits;
      $nb = count($bits);
      
      if ($nb < 1000) {
        print "W: L$span->linenum, span #$span->span_ix, $nb bits: too short to derive framing, using previous ".$prev_framing->to_string()."\n";
        $span->framing = $prev_framing;
        continue;
      }
      
      // find first start bit (should be right at the start)
      for ($i=0; $i < $nb; $i++) {
        $b = $bits[$i];
        if (0 == $b->value) {
          break;
        }
      }
      
      if ($i != 0) {
        print "W: autopopulate_framings: L$b->linenum, span #$b->span_ix, $nb bits: Late start bit (i=$i)\n";
      }
      
      $i++; // first data bit
      
      $short_stops_score = 0;
      $short_odd_score = 0;
      $short_even_score = 0;
      
      // assume frame len of 10
      for ($j=$i; $j < ($nb - 9); $j += 10) {
        $short_stops_score += $bits[$j+8]->value;
        $ones = 0;
        // check all data bits, plus the parity bit (8 bits); count the ones
        for ($k=$j; $k < $j+8; $k++) {
          $ones += $bits[$k]->value;
        }
        if ($ones & 1) {
          $short_odd_score++;
        } else {
          $short_even_score++;
        }
      }
      
      $long_stops_score     = 0;
      $double_stop_score    = 0;
      $long_7bit_odd_score  = 0;
      $long_7bit_even_score = 0;
      $long_8bit_odd_score  = 0;
      $long_8bit_even_score = 0;
      
      // now assume frame len of 11
      for ($j=$i; $j < ($nb - 10); $j+=11) {
        $long_stops_score += $bits[$j+9]->value;
        $double_stop_score += $bits[$j+8]->value;
        $ones = 0;
        // check all data bits, plus the potential parity bit (8 bits); count the ones
        for ($k=$j+1; $k < $j+9; $k++) {
          $ones += $bits[$k]->value;
        }
        if ($ones & 1) {
          $long_7bit_odd_score++;
        } else {
          $long_7bit_even_score++;
        }
        // do it again but include an extra bit, another potential parity bit
        $ones += $bits[$j+9]->value;
        if ($ones & 1) {
          $long_8bit_odd_score++;
        } else {
          $long_8bit_even_score++;
        }
      }

      //print "short_stops_score = $short_stops_score\n";
      //print "short_even_score = $short_even_score\n";
      //print "short_odd_score = $short_odd_score\n";
      
      //print "long_stops_score = $long_stops_score\n";
      //print "double_stop_score = $double_stop_score\n";
      
      // if short_stops_score > long_stops_score
      //   7E1, 7O1, 8N1
      // else
      //   if double_stop_score ~= long_stops_score
      //     7E2, 7O2, 8N2
      //   else
      //     8E1, 8O1
      
      $framelen = 0;
      $parity = "";
      $stops = 0;
      
      // $epsilon is "approximately zero"
      $epsilon = $nb / 320;
      
      if ($short_stops_score > ($long_stops_score * 1.1)) {
        // 7E1/7O1: 0xxxxxxxP1  }
        // 8N1:     0xxxxxxxx1  } "short"
        // for a perfect signal,
        // 7E1: short_odd_score = 0, short_even_score = lots
        // 7O1: short_odd_score = lots, short_even_score = 0
        // 8N1: short_odd_score = some, short_even_score = some
        $stops = 1;
        if ($short_odd_score < $epsilon) {
          // 7E1
          $framelen = 7;
          $parity = "E";
        } else if ($short_even_score < $epsilon) {
          // 7O1
          $framelen = 7;
          $parity = "O";
        } else {
          // 8N1
          $framelen = 8;
          $parity = "N";
        }
      } else if (abs($double_stop_score - $long_stops_score) < $epsilon) {
        // 7E2/7O2: 0xxxxxxxP11 } "long"
        // 8N2:     0xxxxxxxx11 }
        $stops = 2;
        if ($long_7bit_odd_score < $epsilon) {
          // 7E2
          $framelen = 7;
          $parity = "E";
        } else if ($long_7bit_even_score < $epsilon) {
          // 7O2
          $framelen = 7;
          $parity = "O";
        } else {
          // 8N2
          $framelen = 8;
          $parity = "N";
        }
      } else {
        // 8E1/8O1: 0xxxxxxxxP1
        $stops = 1;
        $framelen = 8;
        if ($long_8bit_odd_score < $epsilon) {
          // 8E1
          $parity = "E";
        } else {
          // 8O1
          $parity = "O";
        }
      }
      
      $framing = new DataFraming;
      $framing->stops        = $stops;
      $framing->framelen     = $framelen;
      $framing->parity       = $parity;
      //$framing->autodetected = TRUE;
      
      $tbt->spans[$sn]->framing = $framing;
      $prev_framing = $framing;
      
      print "Framing: L$b->linenum, span #$b->span_ix, $nb bits: ".$span->framing->to_string()."\n";
      
    }
    
    return TBT_E_OK;
    
  }
*/


  function spans_detect_and_convert_dummy_bits (ParsedTibet &$tbt) : int {
  
    $dummies = array();
  
    // for a dummy bit span, we need <leader> <data> <leader>,
    // so we start at 1 and end at N-2
    for ($i=1; $i < (count($tbt->spans) - 1); $i++) {
      $prev = $tbt->spans[$i-1];
      $cur  = $tbt->spans[$i];
      $next = $tbt->spans[$i+1];
      if (    (get_class($prev) != "TibetLeader")
           || (get_class($cur)  != "TibetData")
           || (get_class($next) != "TibetLeader")) {
        continue; // nope
      }
      $num_bits = count($cur->bits);
      if ($num_bits < 10) {
        continue; // nope
      }
      // candidate span may have some leader tone following the
      // data burst, so we need to ignore that.
      for ($end=($num_bits - 1); ($end>=0) && ($cur->bits[$end]->value == 1); $end--) { }
      
      // $end should now point to the last zero in the chunk
      if ($end != 7) {
        continue; // nope
      }
      
      // OK, expect &AA
      $bits = $cur->bits;
      
      if (    !$bits[0]->value
           && !$bits[1]->value
           &&  $bits[2]->value
           && !$bits[3]->value
           &&  $bits[4]->value
           && !$bits[5]->value
           &&  $bits[6]->value
           && !$bits[7]->value) {
        print "M: line $cur->linenum: Dummy byte detected.\n";
        $dummies[] = $i;
      }
      
    }
    
    // rather than mess about trying to delete elements from
    // the spans list, which would mess up the numbering in
    // dummies, we'll just set them to NULL.
    foreach ($dummies as $k=>$span_ix) {
      $tdb = new DummyByte;
      
      $tdb->linenum          = $tbt->spans[$span_ix]->linenum;
      $tdb->pre_leader_cycs  = $tbt->spans[$span_ix-1]->cycles;
      $tdb->post_leader_cycs = $tbt->spans[$span_ix+1]->cycles;
      $tdb->value            = 0xAA;
      
      $tbt->spans[$span_ix] = $tdb;
      
      // delete the formerly leader spans:
      $tbt->spans[$span_ix - 1] = NULL;
      $tbt->spans[$span_ix + 1] = NULL;
    }
    
    $spans_new = array();
    for ($i=0; $i < count($tbt->spans); $i++) {
      // DON'T rewrite the span indices. We want these to reflect
      // the original lineup in the TIBET file, so <leader N-1> <data N> <leader N+1>
      // will end up with a pair of discontinuities: ... N-3, N-2, N, N+2, N+3 ...
      if (isset($tbt->spans[$i])) { // now skip the NULLs
        $spans_new[] = $tbt->spans[$i];
      }
    }
    
    //print "orig: ".count($tbt->spans).", final: ".count($spans_new)."\n";

    $tbt->spans = $spans_new; // replace orig array
    
    return TBT_E_OK;
  }

  
  function build_uef (ParsedTibet $tbt,
                      int $chunk_to_use_for_data,
                      int $use_chunk_112_for_silence,
                      int $omit_chunk_117, // 0.6
                      string &$uef,
                      string &$msg) : int {
  
    // header, versions
    $uef = "UEF File!\x00\x0a\x00";
      
    // origin chunk
    $origin = "Created with ".APPNAME." v".TIBETUEF_VERSION."\0";
    $orglen = strlen($origin);
    $uef .= "\x00\x00".le32($orglen).$origin;
    
    $limit = count($tbt->spans);
    
    $framing = new DataFraming;
    
    $cycs_to_steal = 0;
    
    // 0.5
    $cur_active_baud = 1200;
    
    foreach ($tbt->spans as $sn => $span) {
    
      if (gettype($span) != "object") {
        print "B: Bad span type: \"".gettype($span)."\"\n";
        return TBT_E_BUG;
      }
      $type = get_class($span);
      $chunkbuf="";
      $chunktype = 0;
      
      if ("TibetLeader" == $type) {
        // we (maybe) stole some 1-cycles from this leader to pad the
        // preceding data cycle
        $span->cycles -= $cycs_to_steal;
      }
      
      $cycs_to_steal = 0;
      
      if ("TibetLeader" == $type) {
        $chunktype = 0x110;
        // may need multiple chunks
        // 0.4 -- not any more -- we handle this earlier now,
        // in a separate span-processing pass,
        // because there's a potential problem with chunk &111
        // which amalgamates leader spans
        /*
        for ($rem = $span->cycles; $rem > 0; $rem -= 0xffff) {
          $num_cycs = $rem;
          if ($num_cycs > 0xffff) {
            $num_cycs = 0xffff;
          }
          //~ print "M: L$span->linenum, span $span->span_ix: Leader: $num_cycs cycs\n";
          $e = build_uef_leader ($num_cycs, $chunkbuf);
          if (TBT_E_OK != $e) { return $e; }
          $uef .= wrap_chunk ($chunktype, $chunkbuf, $msg);
        }
        */
        $e = build_uef_leader ($span->cycles, $chunkbuf);
        if (TBT_E_OK != $e) { return $e; }
        $uef .= wrap_chunk ($chunktype, $chunkbuf, $msg);
      } else if ("TibetSilence" == $type) {
        // 0.8
        if ($use_chunk_112_for_silence) {
            // complicated: multiple chunks may be needed
          $e = build_uef_silence_112($span, $uef, $msg);
        } else {
          $e = build_uef_silence_116($span, $chunkbuf);
          $uef .= wrap_chunk (0x116, $chunkbuf, $msg);
        }
        if (TBT_E_OK != $e) { return $e; }
      } else if ("TibetData" == $type) {
        if (count($span->cycles) > 0) {
          $span->framing = $framing; // assign current framing value
          $trailing_1_cycles = 0;
          if ($span->squawk) {
            $chunktype = 0x114;
            $e = build_uef_squawk($span, $chunkbuf, $trailing_1_cycles);
          } else {
            $e = build_uef_data ($span,
                                 $cur_active_baud, // 0.5
                                 $chunkbuf,
                                 $chunktype,
                                 $cycs_to_steal, // 0.7: can be -ve now, => same as trailing_1_cycles
                                 $chunk_to_use_for_data);
          }
          // 0.7: error handling for chunk &114:
          if (TBT_E_OK == $e) {
            // do not create chunk on error, or void-chunk condition
            $uef .= wrap_chunk ($chunktype, $chunkbuf, $msg);
          }
          // trap & nullify void-chunk error:
          if (TBT_E_ZL_CHUNK == $e) { $e = TBT_E_OK; }
          // abort on any other error:
          if (TBT_E_OK != $e) { return $e; }
          
          // assign unused trailing 1-cycles to subsequent leader cycle
          // FIXME: consider doing this in prior separate pass, in separate function
          
          // 0.7
          if ($cycs_to_steal < 0) {
            // negative cycs_to_steal is same as trailing_1_cycles
            $trailing_1_cycles = -$cycs_to_steal;
            $cycs_to_steal = 0;
          }
          
          //if ($span->squawk && ($sn+1 < $limit) && (get_class($tbt->spans[$sn+1]) == "TibetLeader")) {
          if (($trailing_1_cycles > 0) && ($sn+1 < $limit) && (get_class($tbt->spans[$sn+1]) == "TibetLeader")) {
            print "M: Assign $trailing_1_cycles trailing 1-cycles to subsequent leader\n";
            $tbt->spans[$sn+1]->cycles += $trailing_1_cycles;
          }
          
        } else {
          print "W: skipped zero-length data section\n";
        }
      } else if ("DataFraming" == $type) {
        $framing = $span;
      } else if ("BaudRate" == $type) {
        if ($span->rate != $cur_active_baud) {
          // 0.6:
          if ( $omit_chunk_117 ) {
            print "W: Omitting chunk &117 (baud rate) as instructed.\n";
          } else {
            $baudrate = $span;
            $baud_uef = "";
            build_uef_baud($baudrate->rate, $baud_uef);
            $uef .= wrap_chunk (0x117, $baud_uef, $msg);
            // 0.5:
            $cur_active_baud = $baudrate->rate;
          }
        }
      } else if ("TimeHint" == $type) {
        // paste this text into the UEF
        $chunkbuf = sprintf("time: %f seconds\0", $span->timestamp);
        $uef .= wrap_chunk (0x120, $chunkbuf, $msg);
      } else if ("DummyByte" == $type) {
        $dummy_byte="";
        build_dummy_byte($span, $dummy_byte); // dummy_byte populated
        $uef .= wrap_chunk (0x111, $dummy_byte, $msg);
      } else {
        print "B: Bad span class: \"$type\"\n";
        return TBT_E_BUG;
      }
    }
    return TBT_E_OK;
  }
  
  function build_dummy_byte (DummyByte $db, string &$chunkbuf) : int {
    $chunkbuf = le16($db->pre_leader_cycs).le16($db->post_leader_cycs);
    return TBT_E_OK;
  }
  
  function build_uef_baud (int $baud, string &$chunkbuf) : int {
    $chunkbuf = le16($baud);
    return TBT_E_OK;
  }
  
  function build_uef_leader (int $num_cycs, string &$chunkbuf) : int {
    $chunkbuf = le16($num_cycs);
    return TBT_E_OK;
  }
  
  function build_uef_silence_116 (TibetSilence $tbs, string &$chunkbuf) : int {
    $chunkbuf = uef_float($tbs->secs);
    return TBT_E_OK;
  }
  
  // 0.8
  // more complicated than the others, as it may generate multiple chunks
  // $uef is passed in
  function build_uef_silence_112 (TibetSilence $tbs, string &$uef, string &$msg) : int {
    // chunk 112 expresses silence as equivalent 2403.8 Hz cycles
    // if gap is large, multiple chunks will be needed ...
    // two byte field, so maximum gap in a single chunk is (65535 / 2403.8) = 27.263 seconds
    // not very long!
    $num_cycs = (int) round($tbs->secs * (2000000.0 / 832.0)); // correct frequency value
    if ($num_cycs == 0) {
      print "W: silence as &112: tiny gap (".$tbs->secs." s); round up to 1/2400\n";
      $num_cycs = 1;
    }
    // multiple chunks needed
    for ( $rem = $num_cycs; $rem > 0; $rem -= 65535 ) {
      $chunkbuf = le16(($rem > 65535) ? 65535 : $rem);
      $uef .= wrap_chunk(0x112, $chunkbuf, $msg);
    }
    return TBT_E_OK;
  }
  
  function build_uef_squawk (TibetData $tbd,
                             string &$chunkbuf,
                             int &$trailing_unused_1_cycles) : int {
                             
    $num_cycles = 0.0;
    $cycs_buf = "";
    $bitcount=0;
    $b=0;
    $cycle_count=0;
    $zero_half_cycle_count = 0;
    
    // determine length of trailing leader section
    
    // e.g., count=2, one trailing 2400
    // 01
    //  ^ count-1
    // ^ limit
    
//print "cyc_count = ".count($tbd->cycles)."\n";
    
    // count down from num cycles to 0, expecting cycle value of 1
    // (i.e. trailing 1-cycles which should be leader instead);
    // stop when first 0-cycle is found; this becomes the limit
    for ($limit = count($tbd->cycles) - 1; $limit >= 0; $limit--) {
      if (0 == $tbd->cycles[$limit]->value) {
        break;
      }
    }
    
    // and what remains at the end is the trailing unused 1-cycles
    // to be returned to the caller
    $trailing_unused_1_cycles = count($tbd->cycles) - (1 + $limit);
    
    // 0.7: prevent void squawk chunks from happening
    if ($limit == -1) {
      print "W: squawk: all cycles are 1-cycles! no actual squawk data! ".
            "do not create chunk &114\n";
      return TBT_E_ZL_CHUNK;
    }
    
//print "M: L#$tbd->linenum, span $tbd->span_ix: Squawk: ";
    for ($i=0; $i <= $limit; $i++) {
      if (0 == $tbd->cycles[$i]->value) {
        $zero_half_cycle_count++; // number of '-' chars in TIBET
      }
      // a cycle is either two '-'s or one '.'
      if ((2 == $zero_half_cycle_count) || (1 == $tbd->cycles[$i]->value)) {
        // cycle available
//print $tbd->cycles[$i]->value ? "S" : "L";
        $zero_half_cycle_count = 0; // reset
        $b <<= 1;
        $b |= $tbd->cycles[$i]->value;
        $bitcount++;
        $cycle_count++;
        if (8 == $bitcount) {
          // bit complete
          $cycs_buf .= chr($b);
          $b = 0;
          $bitcount = 0;
        }
      }
    }
//print "\n";
    if ($zero_half_cycle_count != 0) {
      $ln = $tbd->cycles[$i-1]->linenum;
      $span_ix = $tbd->cycles[$i-1]->span_ix;
      print "W: line $ln, span $span_ix: ".
            "finished squawk with zero_half_cycle_count=$zero_half_cycle_count (want 0)\n";
    }
    if ($bitcount != 0) {
      // there are bits remaining; add them to the buffer
      $b <<= (8 - $bitcount);
      $cycs_buf .= chr($b);
    }
    
//print "build_uef_squawk: num_cycles = $num_cycles\n";
//for ($i=0; $i < strlen($cycs_buf); $i++) {
//  printf ("%02x ", ord($cycs_buf[$i]));
//}
//print "\n";
    
    // fix in v0.4: cycle count field incorrectly contained byte count
    $chunkbuf = le24($cycle_count)."WW".$cycs_buf;

    return TBT_E_OK;
    
  }
  
  
  function build_uef_data (TibetData $tbd,
                           int $baud, // 0.5: baud, for chunk &114
                           string &$chunkbuf,
                           int &$chunktype_used,
                           int &$cycs_to_steal,
                           int $chunk_to_use_for_data) {
                           //int $chunk_102_interpretation) : int {
                           
    $cycs_to_steal = 0;
    $e = TBT_E_OK;
    
    //~ print "build_uef_data: framing is ".$tbd->framing->to_string()."\n";

    // If chunk &100 is requested but framing is incompatible,
    // use chunk &104 instead.
    if ($tbd->framing->to_string() != "8N1") {
      /* cannot use chunk &100 */
      if (0x100 == $chunk_to_use_for_data) {
        $chunk_to_use_for_data = 0x104;
      }
    }
    
    // 0.7: sanity check for zero-length chunk errors
    $chunkbuf_local = "";
    
    // Otherwise just use whatever chunk type was requested.
    
    if (0x100 == $chunk_to_use_for_data) {
        $e = build_uef_data_100($tbd, $chunkbuf_local, $cycs_to_steal);
    } else if (0x102 == $chunk_to_use_for_data) {
        $e = build_uef_data_102($tbd, $chunkbuf_local, $cycs_to_steal); //, $chunk_102_interpretation);
    } else if (0x104 == $chunk_to_use_for_data) {
        $e = build_uef_data_104($tbd, $chunkbuf_local, $cycs_to_steal);
    } else if (0x114 == $chunk_to_use_for_data) {
        $e = build_uef_data_114($tbd, $baud, $chunkbuf_local, $cycs_to_steal); // 0.5: baud
    }
    
    // 0.7: suppress zero-length generated chunk, it's probably all 1-bits
    // (not sure why this happens, something to do with concatenating TIBETs)
    if (strlen($chunkbuf_local) == 0) {
      printf("W: Zero-length data chunk, type &%x\n", $chunk_to_use_for_data);
//print "count(bits) = ".count($tbd->bits).", cycs_to_steal = $cycs_to_steal\n";
//print_r($tbd->bits);
      $e = TBT_E_ZL_CHUNK;
      // this "zero-length chunk" problem happens when
      // the entire chunk is 1-cycles.
      // So, we have the *opposite* of a "cycs to steal"
      // situation here; this is a "cycs to donate" situation.
      if (0 != $cycs_to_steal) {
        print "E: Impossible? Zero-length chunk, but nonzero cycs to steal from subsequent leader?!\n";
        return TBT_E_BUG;
      }
      // OK, so actually we probably have some 1-cycles to donate.
      // Sanity check that all bits are 1s. (Still don't know why this happens.)
      for ($i=0; $i < count($tbd->bits); $i++) {
        if ($tbd->bits[$i]->value != 1) {
          print "E: Checking empty chunk data: should be all 1s, but found a 0 in here!\n";
          return TBT_E_BUG;
        }
      }
      $cycs_to_steal = -count($tbd->bits) * 2;
      print "W: donating ".(count($tbd->bits) * 2).
            " 1-cycles from empty chunk (chunk was all 1s somehow)\n";
    } else {
      $chunkbuf .= $chunkbuf_local;
    }
    
    $chunktype_used = $chunk_to_use_for_data; // out
    
    return $e;
    
  }
  
  
  function build_uef_data_114 (TibetData $tbd,
                               int $baud, // 0.5
                               string &$chunkbuf,
                               int &$cycs_to_steal) : int {
    $bits = $tbd->bits;
    $nb = count($bits);
    $chunkbuf="   WW";
    
    for ($i=0, $total_cycs=0, $bitpos=0, $v=0, $cycs_to_add=0;
         $i < $nb;
         $i++) {
         
      $b = $bits[$i];
      
      $cycs_to_add = ($b->value == 1) ? 2 : 1;
      
      // 0.5
      if ($baud == 300) {
        $cycs_to_add *= 4;
      }
      
      for ($n=0; $n < $cycs_to_add; $n++) {
        $v <<= 1;
        $v |= ($b->value == 1) ? 1 : 0;
        $bitpos++;
        $total_cycs++;
        if ($bitpos == 8) {
          // end of UEF byte; 8 cycles inserted
          $chunkbuf .= chr($v);
          $bitpos = 0;
        }
      }

    }
    
    if ($bitpos != 0) {
      // rem bits
      $v <<= (8 - $bitpos);
      $chunkbuf .= chr($v);
    }
    
    // rewrite total cycs in chunk header
    $chunkbuf[0] = chr($total_cycs         & 0xff);
    $chunkbuf[1] = chr(($total_cycs >> 8 ) & 0xff);
    $chunkbuf[2] = chr(($total_cycs >> 16) & 0xff);
    
    return TBT_E_OK;
    
  }
  
  function build_uef_data_100 (TibetData $tbd,
                               string &$chunkbuf,
                               int &$cycs_to_steal) : int { // cycs will be double this
                               
    $bits = $tbd->bits;
    $nb = count($bits);
    
    $s = "";
    $bitnum = -1; // expecting start bit
    $late_start_bit = 0;
    $bits_to_steal = 0;
    
    for ($i=0; $i < $nb; $i++) {
      $b = $bits[$i];
      if ($bitnum == -1) {
        if ($b->value != 0) {
          if ( ! $late_start_bit ) {
            print "W: build_uef_data_100: line $b->linenum, span #$b->span_ix, bit $i: Late start bit\n";
          }
          $late_start_bit = 1; // latch, to avoid error message spam
          continue;
        }
        $late_start_bit = 0; // unlatch
        $bitnum++; // bitnum = 0
        $v = 0;    // byte value
      } else if (($bitnum >= 0) && ($bitnum <= 7)) {
        $v >>= 1;
        $v |= (($bits[$i]->value) << 7) & 0x80;
        $bitnum++;
      } else { // bitnum = 8
        // byte finished
        $s .= chr($v);
        // expect stop bit
        if ($bits[$i]->value != 1) {
          print "W: build_uef_data_100: line $b->linenum, span #$b->span_ix, bit $i: Bad stop bit\n";
        }
        $bitnum = -1; // go back to expecting start bit
      }
    }
    
    if ($bitnum != -1) {
      // byte unfinished
      // polish it off by stealing 1-bits from subsequent leader tone
      $rem = (8 - $bitnum);
//print "rem = $rem\n";
      for ($i=0; $i < $rem; $i++) {
        $v >>= 1;
        $v |= 0x80;
      }
      $s .= chr($v); // store final byte
      $bits_to_steal += $rem + 1; // +1 for stop bit
    }

    $chunkbuf = $s;
    
    $cycs_to_steal = $bits_to_steal * 2;
    
    return TBT_E_OK;
    
  }
  
  
  
  function build_uef_data_104 (TibetData $tbd,
                               string &$chunkbuf,
                               int &$cycs_to_steal) : int {

    /*
      The first byte holds the number of data bits per packet,
      not counting start/stop/parity bits.

      The second byte holds the ascii code for 'N', 'E' or 'O',
      which specifies that parity is not present, even or odd.

      The third byte holds information concerning stop bits.
      If it is a positive number then it is a count of stop bits.
      If it is a negative number then it is a negatived count of
      stop bits to which an extra short wave should be added.
    */
    
    $frame7 = ($tbd->framing->framelen == 7) ? 1 : 0;
    $stops1 = ($tbd->framing->stops == 1)    ? 1 : 0;
    $parity = ($tbd->framing->parity != "N") ? 1 : 0;

//print_r($tbd->framing->stops); print "\n";
//print "stops = $tbd->framing->stops \n";
    
    $s = chr($tbd->framing->framelen).
         $tbd->framing->parity.
         chr($tbd->framing->stops);
         
    $bits = $tbd->bits;
    $nb = count($bits);
    $wordlen = $tbd->framing->framelen;
    $framelen =   $wordlen
                + (($tbd->framing->parity == "N") ? 0 : 1)
                + $tbd->framing->stops;
    $late_start_bit = 0;
    $bitnum = -1;
    $bits_to_steal = 0;
    
    // 7E1/7O1: 0xxxxxxxP1
    // 8N1:     0xxxxxxxx1
    // 7E2/7O2: 0xxxxxxxP11
    // 8N2:     0xxxxxxxx11
    // 8E1/8O1: 0xxxxxxxxP1
    
    for ($i=0; $i < $nb; $i++) {
    
      $b = $bits[$i];
      
      if ($bitnum == -1) {
        if ($b->value != 0) {
          if ( ! $late_start_bit ) {
            print "W: build_uef_data_104: line $b->linenum, span #$b->span_ix, bit $i: Late start bit\n";
          }
          $late_start_bit = 1; // latch, to avoid error message spam
          continue;
        }
        $late_start_bit = 0; // unlatch
        //$bitnum++; // bitnum = 0
        $v = 0;    // byte value
      } else if (($bitnum >= 0) && ($bitnum <= ($wordlen - 1))) {
//die();
        $v >>= 1;
        $v |= (($bits[$i]->value) << 7) & 0x80;
        //$bitnum++;
      } else if ($bitnum == $wordlen) {
        // byte finished
        if ($wordlen == 7) {
          // extra shift needed for 7-bit word
          $v >>= 1;
          $v &= 0x7f;
        }
        $s .= chr($v);
        //$bitnum++;
      }
      
//print "?\n"; die();

//print "bitnum=$bitnum\n";

//print "parity=$parity , frame7=$frame7 \n";
      
      if ($bitnum == 7) {
        if ($parity && $frame7) {
          // 7E1, 7O1, 7E2, 7O2
          // parity bit
          if ( ! check_parity ($v, $bits[$i]->value, $tbd->framing->parity) ) {
            print "W: build_uef_data_104: line $b->linenum, span #$b->span_ix, bit $i: Bad parity bit\n";
          }
        }
      } else if ($bitnum == 8) {
        if ($parity && ! $frame7) {
          // 8E1, 8O1
          // parity bit
          if ( ! check_parity ($v, $bits[$i]->value, $tbd->framing->parity) ) {
            print "W: build_uef_data_104: line $b->linenum, span #$b->span_ix, bit $i: Bad parity bit\n";
          }
        } else {
          // 7E1, 7O1, 8N1, 7E2, 7O2, 8N2
          // first stop bit
          if ($bits[$i]->value != 1) {
            print "W: build_uef_data_104: line $b->linenum, span #$b->span_ix, bit $i: Bad stop bit\n";
          }
          // if 7E1, 7O1, 8N1, byte is now over
          if ($frame7 && $parity) {
            // 7E1, 7O1
            $bitnum = -2;
          } else if (! $frame7 && ! $parity && $stops1) {
            // 8N1
            $bitnum = -2;
          }
        }
      } else if ($bitnum == 9) {
        // 7E2, 7O2, 8N2, 8E1, 8O1
        // second stop bit
        if ($bits[$i]->value != 1) {
          print "W: build_uef_data_104: line $b->linenum, span #$b->span_ix, bit $i: Bad stop bit\n";
        }
        $bitnum = -2;
      }
      
      $bitnum++;
      
    } // next bit
    
    
    if ($bitnum != -1) {
      // byte unfinished
      // polish it off by stealing 1-bits from subsequent leader tone
      $rem = ($wordlen - $bitnum);
//print "rem = $rem\n";
      for ($i=0; $i < $rem; $i++) {
        $v >>= 1;
        $v |= 0x80;
      }
      if ($wordlen == 7) {
        // extra shift needed for 7-bit word
        $v >>= 1;
        $v &= 0x7f;
      }
      $s .= chr($v); // store final byte
      $bits_to_steal += $rem + $parity + ($stops1 ? 1 : 2);
    }
    
    $chunkbuf = $s;
    $cycs_to_steal = $bits_to_steal * 2; // out
    
    return TBT_E_OK;
    
  }
  
  
  function build_uef_data_102 (TibetData $tbd,
                               string &$chunkbuf,
                               int &$cycs_to_steal) : int {
                               //int $chunk_102_interpretation) : int {

    $bits = $tbd->bits;
    $nb = count($bits);
    
    // regregex's argument for how this should be implemented was compelling:
    
    // https://stardot.org.uk/forums/viewtopic.php?f=4&t=26822
    
    // ---
    // Chunk &0102 is a raw representation of data bits stored on
    // cassette. Unlike chunk &0100 there are no implicit start/stop
    // bits.
    // The first byte of this chunk is used to calculate chunk length
    // at the bit level. Only the first
    // (chunk length [1] * 8) - (value of first byte)
    // bits are used in this chunk.
    // ---
    
    // Let's assume there are 15 bits of data in the chunk. We need
    // two bytes of data to hold 15 bits, with one bit spare. Hence the
    // chunk is going to look like this (bits):
    
    // ZZZZZZZZ YYYYYYYY xYYYYYYY
    // Interpretation B ($chunk_102_interpretation = 1):
    // If "chunk length" refers to all three bytes of the chunk, then
    // we need:
    
    // (3 * 8) - Z = 15
    // 24 - 15 = Z
    // Z = 9
    
    // When reading a chunk &102 (which we obviously don't do here), it
    // should be possible to auto-detect which interpretation was used
    // by examining that first byte; if it's < 8 then interpretation A
    // was used; if it's >= 8 then B was used. This isn't watertight
    // because it is possible to encode a pathological chunk &102 that
    // has, say, three unused bytes at the end, all of which are
    // "switched off" by that first byte (Z=24 or Z=32), but hey ho.
    
    $rem      = $nb % 8;
    
    if ($rem > 0) {
      $first_byte = 8 - $rem;
    } else {
      $first_byte = 0;
    }
    
    //if ($chunk_102_interpretation == 1) {
    $first_byte += 8;
    //}
    
    $chunkbuf .= chr($first_byte);
    
    for ($i=0, $bitnum=0, $b=0; $i < $nb; $i++, $bitnum++) {
      $b >>= 1;
      $b |= ($bits[$i]->value ? 0x80 : 0);
      if ($bitnum == 7) {
        $chunkbuf .= chr($b);
        $bitnum = -1;
        $b = 0;
      }
    }
    
    // we may have some bits not yet sent.
    // we'll use 1-bits as filler, so that in case the decoder doesn't
    // respect the first byte and carries on sending bits right up to
    // the end of the chunk, they will be leader bits, which is most
    // likely to work.
    if ($bitnum != 0) {
      for (; $bitnum < 8; $bitnum++) {
        $b >>= 1;
        $b |= 0x80;
      }
      $chunkbuf .= chr($b);
    }
    
    // we can have an arbitrary number of bits, so we don't need to 
    // steal filler bits from subsequent leader to complete bytes,
    // as we do for the other data chunk types.
    $cycs_to_steal = 0;
    
    return TBT_E_OK;
    
  }
  
  
  /*
  function my_hexdump (array $mem, bool $include_offset)  {
    $s="";
    //$start_of_line = 1;
    if (!isset($mem) || (count($mem)==0)) { return; }
    $l=count($mem);
    if (defined("HEXDUMP_MAX") && $l>HEXDUMP_MAX) {
      $l=HEXDUMP_MAX;
    }
    $sbuf="";
    for ($i=0;$i<$l;$i++) {
      if (!($i%16)) {
        if ($include_offset) {
          $s.=sprintf ("%02x  ", $i);
        } else {
          $s.="    ";
        }
      }
      $s.=sprintf ("%02x ", $z=ord($mem[$i]));
      if (!ctype_print($w=($mem[$i]))||$z>127||$w==="\r"||$w==="\n") {
        $sbuf.=".";
      } else {
        $sbuf.=$w;
      }
      if ($i%16 == 15) { // append text bit yet?
        $s .= " ".$sbuf."\n";
        $sbuf="";
        $start_of_line = 1;
      }
    }
    // ending
    // append any remaining text bit
    if ($i%16!=0) {
      for ($i=(16-$i%16);$i;$i--) {
        // pad up to start of text bit
        $s.= "   ";
      }
      $s.= " ".$sbuf."\n";
    }
    return $s;
  }
  */
  
  
  function check_parity (int $word, int $parity_bit, string $parity_mode) : bool {
    $num_ones = 0;
    // include bit 7 even if in 7-bit mode, it'll be zero in 7-bit mode so it doesn't matter
    for ($i=0; $i < 8; $i++) {
      $num_ones += ($word & 1);
      $word >>= 1;
    }
    $num_ones += ($parity_bit ? 1 : 0);
    return ($parity_mode == "E") XOR ($num_ones & 1);
  }
  

  
  function frexp ( $f, &$exponent) {
    $exponent = ( floor(log($f, 2)) + 1   );
    return ( $f * pow(2, -$exponent) );
  }
  
  function uef_float (float $f) : string {
    
    $a = array();
    
    $a[3] = 0;

    // sign bit
    if ($f < 0) {
      $f = -$f;
      $a[3] = 0x80;
    }

    // decode mantissa and exponent
    $mantissa = (float) frexp ($f, $exponent);
    $exponent += 126;

    // store mantissa
    $im = (int) ($mantissa * (1 << 24)); // hmm. was cast to u32_t. problem?
    $a[0] = $im&0xff;
    $a[1] = ($im >> 8)&0xff;
    $a[2] = ($im >> 16)&0x7f;

    // store exponent
    $a[3] |= $exponent >> 1;
    $a[2] |= ($exponent&1) << 7;
    
    $buf = "";
    $buf .= chr($a[0]);
    $buf .= chr($a[1]);
    $buf .= chr($a[2]);
    $buf .= chr($a[3]);
    
    return $buf;

  }

  
  function wrap_chunk (int $type, string $in, string &$msg) : string {
    $out = "";
    $len = strlen($in);
    $out .= le16($type);
    $out .= le32($len);
    $out .= $in;
    //printf("Chunk: 0x%04x, payload len 0x%x\n", $type, $len);
    //~ $msg .= sprintf("[_&%03x_len_&%x_] ", $type, $len);
    $msg .= sprintf("0x%03x-0x%04x ", $type, $len);
    return $out;
  }
  
  function le16 (int $i) : string {
    $s = "";
    $s .= chr($i & 0xff);
    $s .= chr(($i >> 8) & 0xff);
    return $s;
  }
  
  function le32 (int $i) : string {
    $s = "";
    $s .= chr($i & 0xff);
    $s .= chr(($i >> 8)  & 0xff);
    $s .= chr(($i >> 16) & 0xff);
    $s .= chr(($i >> 24) & 0xff);
    return $s;
  }
  
  function le24 (int $i) : string {
    $s = "";
    $s .= chr($i & 0xff);
    $s .= chr(($i >> 8)  & 0xff);
    $s .= chr(($i >> 16) & 0xff);
    return $s;
  }
  

  
  function process_line (int $ln,
                         string $line,
                         int &$state,
                         int &$span_ix,
                         bool $insert_timestamps,
                         ParsedTibet &$tbt) : int {
                         
    // FIXME: doesn't quite meet TIBET specifications
    // more checking needed ...
  
    // eliminate comments
    $line_tmp = explode("#", $line);
    $line = $line_tmp[0];
  
    // split by space
    $words_tmp = explode(" ", $line);
    $words = array();
    
    // remove any blank words
    foreach ($words_tmp as $tmp=>$w) {
      $w = trim($w);
      if (strlen($w) > 0) {
        $words[] = $w;
      }
    }
    
    $wc = count($words);
    
    // skip empty lines
    if ($wc == 0) {
      return TBT_E_OK;
    }
    
    $e = TBT_E_OK;
    
    $w0 = $words[0];
    
    // the default state at the start of a parse is STATE_VERSION ...
    if (STATE_VERSION == $state) {
      // version line must be the first non-comment, non-blank
      // line in the file.
      // any subsequent version lines will simply be ignored.
      // (this is deliberate and makes concatenating files easy)
      $e = parse_version ($words, $ln, $tbt->version, $line);
      $state = STATE_IDLE;
    } else if (STATE_IDLE == $state) {
      // this is a whitelist; we could ignore unknown keywords
      // instead, but we'll leave it like this for now
      if ($w0 == "tibet") {
        // duplicate version line; just check it for validity
        $dummy = "";
        $e = parse_version ($words, $ln, $dummy, $line);
        if ($dummy != $tbt->version) {
          print "E: line $ln, span $span_ix: Mismatched duplicate version: $line\n";
          return TBT_E_PARSE_DUP_VERSION;
        }
        // TIBET 0.4: reset framing and baud hints for file concatenation
        $df = new DataFraming; // constructor defaults to 8N1
        $df->linenum = $ln;
        $df->span_ix = $span_ix;
        $tbt->spans[] = $df; // token rather than span
        $br = new BaudRate; // constructor defaults to 1200
        $br->linenum = $ln;
        $br->span_ix = $span_ix;
        $tbt->spans[] = $br; // token rather than span
      } else if ($w0 == "silence") {
        if ($wc != 2) {
          print "E: line $ln, span $span_ix: Bad silence line: $line\n";
          return TBT_E_PARSE_SILENCE;
        }
        $silence = new TibetSilence;
        $silence->linenum = $ln;
        $f = 0.0;
        $e = parse_float ($words[1], $f); // f populated
        if (TBT_E_OK != $e) { return $e; }
        $silence->secs = $f; //(float) $words[1];
        $silence->span_ix = $span_ix;
        $span_ix++;
        if (($silence->secs <= 0.0) || ($silence->secs > 1000000.0)) {
          print "E: line $ln, span $span_ix: Illegal silence length: $words[1]\n";
          return TBT_E_BAD_SILENCE;
        }
        $tbt->spans[] = $silence;
      } else if ($w0 == "leader") {
        if ($wc != 2) {
          print "E: line $ln: Bad leader line: $line\n";
          return TBT_E_PARSE_LEADER;
        }
        $leader = new TibetLeader;
        $leader->linenum = $ln;
        $num_cycs = 0;
        $e = parse_int($words[1], $num_cycs); // $num_cycs populated
        if (TBT_E_OK != $e) {
          print "E: line $ln, span $span_ix: Non-integer leader cycles count: $words[1]\n";
          return $e;
        }
        $leader->cycles  = $num_cycs; //(int) $words[1];
        $leader->span_ix = $span_ix;
        $span_ix++;
        if (($leader->cycles < 1) || ($leader->cycles > 30000000)) {
          print "E: line $ln, span $span_ix: Illegal leader length: $words[1]\n";
          return TBT_E_BAD_LEADER;
        }
        $tbt->spans[] = $leader;
      } else if (($w0 == "squawk") || ($w0 == "data")) {
        if ($wc != 1) {
          print "E: line $ln, span $span_ix: Illegal $w0 line: $line\n";
          return TBT_E_PARSE_DATA;
        }
        $data = new TibetData;
        $data->linenum = $ln;
        $data->span_ix = $span_ix;
        $data->squawk = ($w0 == "squawk");
        $span_ix++;
        $state = STATE_CYCLES;
        $tbt->spans[] = $data;
      } else if ($w0 == "/phase") {
        // don't care; it's partially a function of playback,
        // so I disagree that it should be regarded
      } else if ($w0 == "/speed") {
        // don't care; again, it's a function of playback,
        // not of the source
      } else if ($w0 == "/time") {
        if ($insert_timestamps) {
          $timehint = new TimeHint;
          $timestamp = 0.0;
          $e = parse_float($words[1], $timestamp); // timestamp populated
          if (TBT_E_OK != $e) {
            print "E: line $ln, span $span_ix: Illegal /time hint: $line\n";
            return $e;
          }
          $timehint->timestamp = $timestamp; //(float) $words[1];
          $timehint->linenum = $ln;
          $timehint->span_ix = $span_ix;
          $tbt->spans[] = $timehint; // token rather than span
        }
      } else if ($w0 == "/framing") {
        // quadbike doesn't export this, as it can't detect framing,
        // but it could be added by manually editing a TIBET file.
        // UEF chunk 104 needs to know about non-standard framings, and
        // if they e.g. change in the middle of a block, we stand no
        // chance of detecting them automatically, so
        $df = new DataFraming;
        $df->linenum = $ln;
        $df->span_ix = $span_ix;
        $e = parse_framing ($words[1], $df); // df populated
        if (TBT_E_OK != $e) { return $e; }
        $tbt->spans[] = $df; // token rather than span
      } else if ($w0 == "/baud") {
        // again, not exported by QB
        $br = new BaudRate;
        $br->linenum = $ln;
        $br->span_ix = $span_ix;
        $e = parse_baudrate ($words[1], $br); // br populated
        if (TBT_E_OK != $e) { return $e; }
        $tbt->spans[] = $br; // token rather than span
      } else {
        print "E: line $ln, span $span_ix: Unrecognised: $line\n";
        return TBT_E_PARSE_BAD_LINE;
      }
    } else if (STATE_CYCLES == $state) {
      if ($w0 == "end") {
        $state = STATE_IDLE;
      } else {
        $len = strlen($words[0]);
        for ($i=0; $i < $len; $i++) {
          $span_ix = count($tbt->spans) - 1;
          $span = $tbt->spans[$span_ix]; // TibetData
          if ($words[0][$i] == "-") {
            $cyc = new TibetCycle;
            $cyc->value = 0;
            $cyc->linenum = $ln; //$span->linenum;
            $cyc->span_ix = $span->span_ix;
            $span->cycles[] = $cyc;
          } else if ($words[0][$i] == ".") {
            $cyc = new TibetCycle;
            $cyc->value = 1;
            $cyc->linenum = $ln; //$span->linenum;
            $cyc->span_ix = $span->span_ix;
            $span->cycles[] = $cyc;
          } else if ($words[0][$i] == "P") {
            // P cannot be turned into a bit, so decoders just skip it.
          } else {
            print "E: line $ln, span $span_ix: Bad cycle line: $line\n";
            return TBT_E_PARSE_CYCLES;
          }
          $tbt->spans[$span_ix] = $span; // replace the modified value
        }
      }
    }
    
    if (TBT_E_OK != $e) { return $e; }
    
//print "\n";
    return TBT_E_OK;
    
  }
  
  
  function parse_float (string $w, float &$f) : int {
    $len = strlen($w);
    $dp_count=0;
    if ($len > 50) {
      return TBT_E_BAD_FLOAT;
    }
    for ($i=0; $i < $len; $i++) {
      $c = $w[$i];
      if ($c == ".") {
        if ($dp_count != 0) { // only one decimal point allowed
          return TBT_E_BAD_FLOAT;
        } else if ($i == ($len - 1)) { // decimal point may not be the final character
          return TBT_E_BAD_FLOAT;
        }
        $dp_count++;
      } else if ( ! ctype_digit ($c) ) { // chars other than digits and decimal point are illegal
        return TBT_E_BAD_FLOAT;
      }
    }
    $f = (float) $w;
    return TBT_E_OK;
  }
  
  function parse_int (string $w, int &$i) : int {
    $len = strlen($w);
    if ($len > 19) {
      return TBT_E_BAD_INT;
    }
    for ($j=0; $j < $len; $j++) {
      $v = $w[$j];
      if (!ctype_digit($v)) {
        return TBT_E_BAD_INT;
      }
    }
    $i = (int) $w;
    return TBT_E_OK;
  }
    
  
  function parse_framing (string $w, DataFraming &$f) : int {
    if (strlen($w) != 3) { return FALSE; }
    if (($w[0] != "7") && ($w[0] != "8")) { return FALSE; }
    if (($w[1] != "N") && ($w[1] != "O") && ($w[1] != "E")) { return FALSE; }
    if (($w[2] != "1") && ($w[2] != "2")) { return FALSE; }
    $framelen = 0;
    $e = parse_int ($w[0], $framelen); // framelen populated
    if (TBT_E_OK != $e) { return $e; }
    $f->framelen = $framelen;
    $f->parity = $w[1];
    $num_stops = 0;
    $e = parse_int ($w[2], $num_stops); // num_stops populated
    if (TBT_E_OK != $e) { return $e; }
    $f->stops = $num_stops;
    return TBT_E_OK;
  }
  
  function parse_baudrate (string $w, BaudRate &$r) : int {
    $i = 0;
    $e = parse_int ($w, $i); // i populated
    if (TBT_E_OK != $e) { return $e; }
    $r->rate = $i;
    return TBT_E_OK;
  }
  
  
  function parse_version (array $words, int $ln, string &$tbt_version, string $line) : int {
    $wc = count($words);
    if ($words[0] != "tibet") {
      print "E: Version line not found: $line\n";
      return TBT_E_PARSE_VERSION;
    }
    if ($wc != 2) {
      print "E: line $ln: Bad version line: $line\n";
      return TBT_E_PARSE_VERSION;
    }
    // 0.8: switched to major/minor version paradigm
    $tbt_version = $words[1];
    $v = explode(".", $tbt_version);
    if (count($v) != 2) {
      print "E: line $ln: Bad version: $tbt_version\n";
      return TBT_E_BAD_VERSION;
    }
    //if (TIBET_VERSION_STG != $tbt_version) {
    if ($v[0] != TIBET_MAJOR_VERSION) {
      print "E: line $ln: Incompatible TIBET version: $tbt_version\n";
      return TBT_E_INCOMPATIBLE;
    }
    return TBT_E_OK;
  }
  
  
  function tbt_process (string $ip, bool $insert_timestamps, ParsedTibet &$tbt) : int {
    $state = STATE_VERSION;
    $lines = explode ("\n", $ip);
    $span_ix = 0;
    print count($lines)." lines.\n";
    foreach ($lines as $ln=>$v) {
      $ln++; // linenum; 1-indexed
      $e = process_line ($ln, $v, $state, $span_ix, $insert_timestamps, $tbt); // state, tbt, span_ix modified
      if (TBT_E_OK != $e) { return $e; }
    }
    if ((STATE_IDLE != $state) && (STATE_DATA != $state)) {
      print "W: Finished in unexpected state $state\n";
    }
    print "TIBET version: $tbt->version\n";
    return TBT_E_OK;
  }
  
  
  function usage(string $argv0) {
    print "Usage:\n\n";
    print "  php -f $argv0 [options] <input TIBET file> <output UEF file>\n\n";
    print "where [options] may be:\n\n";
    //print "    +f activates automatic framing detection\n";
    //print "      (overrides all framing lines in input)\n\n";
    print "  +t       use \"/time\" hints in TIBET file to insert &120 label chunks into UEF\n";
    print "           (currently breaks beebjit)\n\n";
    print "  +102     use chunk &102 for data\n";
    //print "  +102b                            (interpretation B)\n";
    print "  +104     use chunk &104 for data\n";
    print "  +114     use chunk &114 for data\n\n";
    print "  +112     use chunk &112 instead of &116 for silence\n\n";
    print "  +no-117  omit baud rate chunk &117 (Elkulator compatibility)\n\n";
    print "  +nz      do not compress output UEF file\n";
    print "\n";
  }
  
?>
