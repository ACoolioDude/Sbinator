package engine.backend.system.utils;

import haxe.CallStack;
import haxe.io.Path;
import openfl.Lib;
import openfl.events.UncaughtErrorEvent;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;

class SBCrash {
    private static var initial:Bool = false;
    private static var ignoredClasses:Array<String> = [
        "ApplicationMain",
        "away3d.",
        "lime.",
        "hxcpp.",
        "openfl."
    ];

    public static function init():Void {
        if (initial) return;
        initial = true;

        Sys.println("Engine's crash handler initialized!");

        Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
            UncaughtErrorEvent.UNCAUGHT_ERROR,
            onUncaughtError
        );
    }

    private static function onUncaughtError(e:UncaughtErrorEvent):Void {
        e.preventDefault();
        e.stopPropagation();
        e.stopImmediatePropagation();

        var callstacks:Array<StackItem> = CallStack.exceptionStack();
        if (callstacks == null || callstacks.length == 0) callstacks = CallStack.callStack();

        onCrashShow(e.error, callstacks);
    }

    private static function onClassIgnorance(line:String):Bool {
        for (classes in ignoredClasses) {
            if (line.indexOf(classes) != -1) return true;
        }
        return false;
    }

    private static function onCrashShow(error:Dynamic, stack:Array<StackItem>):Void {
        var errorMsg:String = Std.string(error);

        var lines:Array<String> = [];
        lines.push("\n================= SBINATOR CRASHED =================");
        lines.push('Error: ${errorMsg}');
        lines.push("------------------------------------------------------");
        lines.push("Stack traces:");

        if (stack == null || stack.length == 0) {
            lines.push("   (No stack trace available!)");
        } else {
            var printLine:Int = 0;

            for (item in stack) {
                var formatLine:String = formatStack(item);
                if (formatLine != "" && !onClassIgnorance(formatLine)) {
                    lines.push('   ' + formatLine);
                    printLine++;
                }
            }

            if (printLine == 0) {
                lines.push('   (Stack trace is filtered or stripped)');
                for (item in stack) {
                    lines.push('   [RAW] ' + item);
                }
            }
        }

        var report:String = lines.join("\n");
        Sys.println(report);

        saveCrashLog(report, stack);

        Sys.exit(1);
    }

    private static function saveCrashLog(report:String, stack:Array<StackItem>):Void {
        try {
            var dir:String = Path.join([Path.directory(Sys.programPath()), "crash"]);
            if (!FileSystem.exists(dir)) FileSystem.createDirectory(dir);

            var now:Date = Date.now();
            var fileName:String = "Sbinator_" + DateTools.format(now, "%Y-%m-%d_%H-%M-%S") + ".txt";
            var path:String = Path.join([dir, fileName]);

            var out:FileOutput = File.write(path, false);
            out.writeString("SBinator crash log\n");
            out.writeString('Time: ${now.toString()}\n');
            out.writeString('System: ${SystemUtils.getOSName()}\n');
            out.writeString(report + "\n\n");

            out.writeString("Full stack (unfiltered):\n");
            if (stack != null) {
                for (item in stack) out.writeString('   ' + Std.string(item) + "\n");
            }

            out.close();

            Sys.println("------------------------------------------------------");
            Sys.println('Crash log saved to: ${path}');
            Sys.println("=====================================================");
        } catch (e:Dynamic) {
            Sys.println('Could not save crash log: ${e}');
            Sys.println("=====================================================");
        }
    }

    private static function formatStack(item:StackItem):String {
        switch (item) {
            case FilePos(parent, file, line, col): 
                switch (parent) {
                    case Method(cla, func):
                        var parts:Array<String> = cla.split(".");
                        var className:String = parts[parts.length - 1];
                        return '${className}::${func}() [Line ${line}]';
                    case _:
                        return '(${file}) -> [Line ${line}]';
                }
            case Method(classname, method): return '${classname}.${method}';
            case Module(module): return 'module ${module}';
            case CFunction: return 'C Function';
            case LocalFunction(v): return 'Local Function #${v}';
        }
    }
}