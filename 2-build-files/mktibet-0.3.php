<?php

/*
 *  Quadbike 2
 *  Copyright (C) 2023 'Diminished'

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

  // TODO
  // [ ] override gap lengths for next file
  // [ ] override leader lengths for next file
  // [x] persist baud behaviour, so +b 300 on file 1 causes other files to be 300 unless changed

  // PHP >=7, reduce stupidity
  declare (strict_types=1);

  define ("MKT_E_OK",         0);
  define ("MKT_E_CLI",        1);
  define ("MKT_E_LOAD",       2);
  define ("MKT_E_LARGE_FILE", 3);
  define ("MKT_E_SAVE",       4);
  
  define ("CLI_STATE_IDLE",   0);
  define ("CLI_STATE_LOAD",   1);
  define ("CLI_STATE_EXEC",   2);
  define ("CLI_STATE_NAME",   3);
  define ("CLI_STATE_TIBET",  4);
  define ("CLI_STATE_BAUD",   5);
  
  define ("MAX_FILE_SIZE",        32 * 1024);
  
  define ("DURATION_PRE_GAP_S",      2.0);
  define ("DURATION_MID_GAP_S",      1.0);
  define ("DURATION_POST_GAP_S",     2.0);
  define ("DURATION_LEADER_S",       1.0);
  define ("TIBET_VERSION",           0.4);
  
  define ("MKTIBET_VERSION",         0.3);
  
  define ("DURATION_LEADER_CYCS", (int) (DURATION_LEADER_S * 2400.0));

  $argv = $_SERVER['argv'];
  
  print "\n$argv[0] v".MKTIBET_VERSION."\n\n";

  $e = process($argv);
  
  return $e;

  
  class FileOpts {
  
    var $load;
    var $exec;
    var $baud;
    var $prepend_dummy_byte; // 0.3
    
    var $have_load;
    var $have_exec;
    var $have_baud;
    var $have_no_dummy; // 0.3
    
    function __construct() {
      $this->load = 0xffff1900;
      $this->exec = 0xffff8023;
      $this->baud = 1200;
      $this->prepend_dummy_byte = TRUE; // 0.3
      $this->have_load = 0;
      $this->have_exec = 0;
      $this->have_baud = 0;
      $this->have_no_dummy = 0; // 0.3
    }
    
    function to_string() : string {
      $s="(";
      $s .= sprintf("load &%x; ", $this->load);
      $s .= sprintf("exec &%x; ", $this->exec);
      $s .= "baud ".$this->baud."; ";
      $s .= "prepend_dummy $this->prepend_dummy_byte"; // 0.3
      $s .= ")";
      return $s;
    }
    
  }
  
  
  class TibetFile {
  
    var $mos_name;
    var $path_to_src;
    var $opts;
    var $data;
    var $have_mos_name;
    
    function __construct (int $baud) {
      $this->mos_name=NULL;
      $this->data="";
      $this->path_to_src = "";
      $this->have_mos_name = 0;
      $this->opts = new FileOpts;
      $this->opts->baud = $baud;
      $this->opts->prepend_dummy_byte = TRUE; // v0.3: BeebEm fail
    }
    
    function to_string() : string {
      $s="";
      $s .= "MOS: \"$this->mos_name\", ";
      //$s .= "path: \"$this->path_to_src\", ";
      $s .= $this->opts->to_string();
      return $s;
    }
    
  }

  
  function process(array $argv) {
  
    $files = array();
    $tibet_fn="tibet.tibet";
    
    $e = parse_cli ($argv, $files, $tibet_fn); // files, tibet_fn populated
    if (MKT_E_OK != $e) {
      usage($argv[0]);
      return $e;
    }
    
    $e = fill_missing_names ($files);
    if (MKT_E_OK != $e) { return $e; }

    $e = load_files ($files);
    if (MKT_E_OK != $e) { return $e; }
    
    foreach ($files as $k=>$v) {
      print $v->path_to_src."\n";
      print "  ".$v->to_string();
      print "\n";
    }
    
    $tibet_s = "";
    $e = build_tibet ($files, $tibet_s);
    if (MKT_E_OK != $e) { return $e; }
    
    if (FALSE === @file_put_contents ($tibet_fn, $tibet_s)) {
      print "E: Could not write output file: $tibet_fn\n";
      return MKT_E_SAVE;
    }
    
    print "Wrote ".strlen($tibet_s)." bytes: $tibet_fn\n";
    
    return MKT_E_OK;
  }
  
  
  
  function build_tibet (array $files, string &$out) : int {
    $out .= "tibet ".TIBET_VERSION."\n\n";
    $out .= "silence ".DURATION_PRE_GAP_S."\n\n";
    $num_files = count($files);
    $prev_baud = 0;
    for ($n=0; $n < $num_files; $n++) {
      $f = $files[$n];
      $d = $f->data;
      $len = strlen($d);
      // v0.3: Maddeningly, BeebEm misses the start of the first block unless you
      // send some dummy data first, because ... no, I've no idea why on earth it would do this
      if ($f->opts->prepend_dummy_byte) {
        $out .= "leader ".DURATION_LEADER_CYCS."\n";
        $out .= "data\n----..--..--..--....\nend\n"; // standard MOS 1.2 &AA dummy byte
        $out .= "leader ".DURATION_LEADER_CYCS."\n\n";
      }
      // split into blocks
      for ($i=0, $rem=$len, $bn=0;
           $i < $len;
           $i += 256, $rem -= 256, $bn++) {
        if ($rem < 256) {
          $blklen = $rem;
        } else {
          $blklen = 256;
        }
        $blk_payload = substr ($d, $i, $blklen);
        $blk_built = "";
        $e = build_block ($bn, $rem <= 256, FALSE, $blk_payload, $f, $blk_built);
        if (MKT_E_OK != $e) { return $e; }
        $blk_encoded = "";
        $e = tibet_encode ($blk_built,
                           $f->opts->baud,
                           $prev_baud != $f->opts->baud, // baud changed?
                           $blk_encoded);
        if (MKT_E_OK != $e) { return $e; }
        $leader_cycs = DURATION_LEADER_CYCS;
        $out .= "leader ".$leader_cycs."\n\n";
        $out .= $blk_encoded;
        //printf("%02x len %u\n", $bn, strlen($blk));
        $prev_baud = $f->opts->baud;
      }
      $out .= "leader ".DURATION_LEADER_CYCS."\n\n";
      if ($n < ($num_files - 1)) {
        $out .= "silence ".DURATION_MID_GAP_S."\n\n";
      }
    }
    $out .= "silence ".DURATION_POST_GAP_S."\n\n";
    return MKT_E_OK;
  }
  
  
  function tibet_encode (string $in, int $baud, bool $baud_changed, string &$out) : int {
    $out = "";
    if ($baud_changed) {
      $out .= "/baud ".$baud."\n";
    }
    $out .= "data\n";
    $len = strlen($in);
    $one  = ($baud == 1200) ? ".." : "........";
    $zero = ($baud == 1200) ? "--" : "--------";
    $newline_limit = ($baud == 1200) ? 3 : 0;
    for ($n=0, $x=0; $n < $len; $n++, $x++) {
      $c = ord($in[$n]);
      $out .= $zero; // start bit
      for ($i=0; $i < 8; $i++) {
        $out .= ($c&1) ? $one : $zero;
        $c = ($c >> 1) & 0x7f;
      }
      $out .= $one; // stop bit
      if ($x == $newline_limit) {
        $out .= "\n";
        $x = -1;
      }
    }
    if ($x!=0) { $out .= "\n"; }
    $out .= "end\n\n";
    return MKT_E_OK;
  }
  
  
  function build_block (int $bn,
                        bool $final,
                        bool $locked,
                        string $payload,
                        TibetFile $tf,
                        string &$out) : int {
    $len = strlen($payload);
    $flags = ($final ? 0x80 : 0) | (($len == 0) ? 0x40 : 0) | ($locked ? 1 : 0);
    $hdr = $tf->mos_name.
           "\x00".
           to_le32($tf->opts->load).
           to_le32($tf->opts->exec).
           to_le16($bn).
           to_le16($len).
           chr($flags).
           "\x00\x00\x00\x00";
    $hcrc = acorn_crc($hdr);
    $out = "*" . $hdr . to_be16($hcrc);
    if ($len > 0) {
      $dcrc = acorn_crc($payload);
      $out .= $payload . to_be16($dcrc);
    }
    return MKT_E_OK;
  }
  
  
  function acorn_crc (string $s) : int {
    $crc = 0;
    for ($n=0; $n < strlen($s); $n++) {
      //u8_t i;
      //u32_t c;
      //u16_t h;
      $b = ord($s[$n]);
      $c = $crc;
      $h = ($c>>8) & 0xff;
      $h = $b ^ $h;
      $c = ($c & 0x00ff) | (($h << 8) & 0xff00);
      for ($i=0; $i<8; $i++) {
        //u32_t t;
        $t = 0;
        if ($c & 0x8000) {
          $c = $c ^ 0x810;
          $t = 1;
        }
        $c = 0xffff & ($t | (($c<<1) & 0xfffe));
      }
      $crc = $c;
    }
    return $crc;
  }
  
  
  function to_be16 (int $i) : string {
    $s = "";
    $s .= chr(($i >> 8) & 0xff);
    $s .= chr($i & 0xff);
    return $s;
  }
  
  
  function to_le16 (int $i) : string {
    $s = "";
    $s .= chr($i & 0xff);
    $s .= chr(($i >> 8) & 0xff);
    return $s;
  }
  
  
  function to_le32 (int $i) : string {
    $s = "";
    $s .= chr($i & 0xff);
    $s .= chr(($i >> 8) & 0xff);
    $s .= chr(($i >> 16) & 0xff);
    $s .= chr(($i >> 24) & 0xff);
    return $s;
  }
  
  
  function load_files (array &$files) : int {
    foreach ($files as $k=>$file) {
      $p = $file->path_to_src;
      $f = @file_get_contents($p);
      if (FALSE === $f) {
        print "E: Could not load file: $p\n";
        return MKT_E_LOAD;
      }
      if (strlen($f) > MAX_FILE_SIZE) {
        print "E: File was too large: $p\n";
        return MKT_E_LARGE_FILE;
      }
      $file->data = $f;
      $files[$k] = $file;
    }
    return MKT_E_OK;
  }
  
  
  function fill_missing_names (array &$a) : int {
    foreach ($a as $k=>$file) {
      if ( ! isset($file->mos_name) ) {
        $basename = basename($file->path_to_src);
        $e = check_mos_filename($basename);
        if (MKT_E_OK != $e) { return $e; }
        $file->mos_name = $basename;
        $a[$k] = $file; // replace in array
      }
    }
    return MKT_E_OK;
  }
  
  
  function parse_cli (array $argv, array &$files, string &$tibet_fn) : int {
  
    $opts_done = 0;
    $state = 0;
    $argc = count($argv) - 1;
    
    $have_tibet_filename = 0;
    
    // current working file
    $f = new TibetFile(1200);
    
    $state = CLI_STATE_IDLE;
    
    for ($n=1; $n <= $argc; $n++) {
      $v = $argv[$n];
      if ($state == CLI_STATE_IDLE) {
        if ($v[0] == "+") {
          // opt
          if ($v == "+x") {
            // execution address
            if ($f->opts->have_exec) {
              print "E: Cannot specify exec address twice.\n";
              return MKT_E_CLI;
            }
            $f->opts->have_exec = 1;
            $state = CLI_STATE_EXEC;
          } else if ($v == "+d") {
            // load address
            if ($f->opts->have_load) {
              print "E: Cannot specify load address twice.\n";
              return MKT_E_CLI;
            }
            $f->opts->have_load = 1;
            $state = CLI_STATE_LOAD;
          } else if ($v == "+b") {
            // baud
            if ($f->opts->have_baud) {
              print "E: Cannot specify baud rate twice.\n";
              return MKT_E_CLI;
            }
            $f->opts->have_baud = 1;
            $state = CLI_STATE_BAUD;
          } else if ($v == "+n") {
            // overridden MOS filename
            if ($f->have_mos_name) {
              print "E: Cannot specify MOS filename twice.\n";
              return MKT_E_CLI;
            }
            $f->have_mos_name = 1;
            $state = CLI_STATE_NAME;
          } else if ($v == "+t") {
            // TIBET filename
            if ($have_tibet_filename) {
              print "E: Cannot specify TIBET filename twice.\n";
              return MKT_E_CLI;
            }
            $have_tibet_filename = 1;
            $state = CLI_STATE_TIBET;
          } else if ($v == "+no-dummy") {
            if ($f->opts->have_no_dummy) {
              print "E: Cannot specify no-dummy twice.\n";
              return MKT_E_CLI;
            }
            $f->have_no_dummy = 1;
            $f->opts->prepend_dummy_byte = FALSE;
          } else {
            print "E: unknown option $v\n";
            $e = MKT_E_CLI;
            return $e;
          }
        } else {
          // no '+' => filename, completes file
          $f->path_to_src = $v;
          $files[] = $f;
          // start a new one, but persist the baud from previous one
          $f = new TibetFile($f->opts->baud);
        }
      } else if ($state == CLI_STATE_LOAD) {
        $i=0;
        $e = cli_parse_x32($v, $i);
        if (MKT_E_OK != $e) { return $e; }
        $f->opts->load = $i;
        $state = CLI_STATE_IDLE;
      } else if ($state == CLI_STATE_EXEC) {
        $i=0;
        $e = cli_parse_x32($v, $i);
        if (MKT_E_OK != $e) { return $e; }
        $f->opts->exec = $i;
        $state = CLI_STATE_IDLE;
      } else if ($state == CLI_STATE_BAUD) {
        $i=0;
        $e = cli_parse_baud($v, $i);
        if (MKT_E_OK != $e) { return $e; }
        $f->opts->baud = $i;
        $state = CLI_STATE_IDLE;
      } else if ($state == CLI_STATE_NAME) {
        $e = check_mos_filename($v);
        if (MKT_E_OK != $e) { return $e; }
        $f->mos_name = $v;
        $state = CLI_STATE_IDLE;
      } else if ($state == CLI_STATE_TIBET) {
        $tibet_fn = $v;
        $state = CLI_STATE_IDLE;
      }
    } // next arg
    
    if ( ! $have_tibet_filename ) {
      print "\nE: Must specify output TIBET filename with +t.\n";
      return MKT_E_CLI;
    }
    
    return MKT_E_OK;
    
  }
  
  
  function check_mos_filename (string $v) : int {
    if (strlen($v) > 10) {
      print "E: overridden MOS filename is too long (max 10 chars): $v\n";
      return MKT_E_CLI;
    } else if (strlen($v) == 0) {
      print "E: overridden MOS filename is empty: $v\n";
      return MKT_E_CLI;
    }
    $len = strlen($v);
    for ($n=0; $n < $len; $n++) {
      if ($v[$n] == "\x00") {
        print "E: overridden MOS filename contains null byte\n";
        return MKT_E_CLI;
      }
    }
    return MKT_E_OK;
  }
  
  
  function cli_parse_baud (string $v, int &$baud_out) : int {
    if ($v == "300") {
      $baud_out = 300;
    } else if ($v == "1200") {
      $baud_out = 1200;
    } else {
      print "E: Illegal baud: $v\n";
      return MKT_E_CLI;
    }
    return MKT_E_OK;
  }
  
  
  function cli_parse_x32 (string $v, int &$out) : int {
    $len = strlen($v);
    if ($len == 0) {
      print "E: illegal 32-bit hex: $v\n";
      return MKT_E_CLI;
    }
    // removed because it causes backgrounding on Unix!
    //if ($v[0]=="&") {
    //  $v = substr($v, 1);
    //}
    if (($v[0]=="0") && (($v[1]=="x") || ($v[1]=="X"))) {
      $v = substr($v, 2);
    }
    $len = strlen($v);
    if ($len > 8) {
      print "E: illegal 32-bit hex: $v\n";
      return MKT_E_CLI;
    }
    for ($n=0; $n < $len; $n++) {
      if ( ! ctype_xdigit($v[$n]) ) {
        print "E: illegal 32-bit hex: $v\n";
        return MKT_E_CLI;
      }
    }
    $i=0;
    $e = sscanf($v, "%x", $i);
    if (FALSE === $e) {
      print "E: illegal 32-bit hex: $v\n";
      return MKT_E_CLI;
    }
    $out = $i;
    return MKT_E_OK;
  }
  
  
  function usage (string $argv0) {
    print "\n\nUsage:\n\n";
    print "  php -f $argv0 +t <output TIBET> [opts] <file1> [opts] <file2> [opts] <file3> ...\n\n";
    print "where each per-file [opts] may be:\n\n";
    print "  +x <hex>        specify execute address for next file\n";
    print "  +d <hex>        specify load address for next file\n";
    print "  +b <1200|300>   specify baud rate for next file\n";
    print "  +n <filename>   override MOS filename for next file\n";
    print "  +no-dummy       disable prepending &AA byte before next file\n";
    print "\n";
  }

?>
