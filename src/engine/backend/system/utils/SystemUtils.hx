package engine.backend.system.utils;

import openfl.display.Sprite;
import sys.FileSystem;
import sys.io.File;

class SystemUtils {
    public static function getOSName():String {
        if (FileSystem.exists("/etc/os-release")) {
            try {
                var lines = File.getContent("/etc/os-release").split("\n");
                for (line in lines) {
                    var cleanLine = StringTools.trim(line);

                    if (StringTools.startsWith(cleanLine, "PRETTY_NAME=")) {
                        var parts = cleanLine.indexOf("=");
                        if (parts != -1) {
                            var name = StringTools.trim(cleanLine.substr(parts + 1));
                            if ((StringTools.startsWith(name, '"') && StringTools.endsWith(name, '"')) || (StringTools.startsWith(name, "'") && StringTools.endsWith(name, "'"))) {
                                name = name.substring(1, name.length -1 );
                            }
                            
                            return name;
                        }
                    }
                }
            } catch (e:Dynamic) {}
        }
        return Sys.systemName();
    }
}