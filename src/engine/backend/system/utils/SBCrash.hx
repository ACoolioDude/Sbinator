package engine.backend.system.utils;

import haxe.CallStack;
import openfl.Lib;
import openfl.events.UncaughtErrorEvent;
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

        Sys.println("\n================= SBINATOR CRASHED =================");
        Sys.println('Error: ${errorMsg}');
        Sys.println("------------------------------------------------------");
        Sys.println("Stack traces:");

        if (stack == null || stack.length == 0) {
                Sys.println("   (No stack trace available!)");
        } else {
            var printLine:Int = 0;
    
            for (item in stack) {
                var formatLine:String = formatStack(item);
                if (formatLine != "" && !onClassIgnorance(formatLine)) {
                    Sys.println('   ' + formatLine);
                    printLine++;   
                }
            }

            if (printLine == 0) {
                Sys.println('   (Stack trace is filtered or stripped in released target)');
                for (item in stack) {
                    Sys.println('   [RAW] ' + item);
                }
            }
        }

        Sys.println("\n=====================================================");
        Sys.exit(1);
    }

    private static function formatStack(item:StackItem) {
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