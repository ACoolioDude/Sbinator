package engine.backend.system.utils;

import sys.io.Process;

class SBProcess {
    public static function runCmd(cmd:String, args:Array<String>):String {
        try {
            var p = new Process(cmd, args);
            var stdout = p.stdout.readAll().toString();
            p.close();
            return StringTools.trim(stdout);
        } catch (e:Dynamic) {
            return "N/A";
        }
    }
}