// Credits for CoreCat and ZSolar Dev for GitHub commit code

package data.backend.macro;

class GitHub {
	public static macro function getGitCommitHash():haxe.macro.Expr.ExprOf<String> {
		#if !display
		var pos = haxe.macro.Context.currentPos();

		var process = new sys.io.Process('git', ['rev-parse', 'HEAD']);
		if (process.exitCode() != 0) {
			var message = process.stderr.readAll().toString();
			haxe.macro.Context.info('[WARN] Could not determine current git commit; is this a proper Git repository?', pos);
		}

		var commitHash:String = process.stdout.readLine();
		var commitHashSplice:String = commitHash.substr(0, 7);

		process.close();

		return macro $v{commitHashSplice};
		#else
		var commitHash:String = "";
		return macro $v{commitHashSplice};
		#end
	}

	public static macro function getGitBranch():haxe.macro.Expr.ExprOf<String> {
		#if !display
		var pos = haxe.macro.Context.currentPos();
		var branchProcess = new sys.io.Process('git', ['rev-parse', '--abbrev-ref', 'HEAD']);

		if (branchProcess.exitCode() != 0) {
			var message = branchProcess.stderr.readAll().toString();
			haxe.macro.Context.info('[WARN] Could not determine current git commit; is this a proper Git repository?', pos);
		}

		var branchName:String = branchProcess.stdout.readLine();
		branchProcess.close();
		trace('Git Branch Name: ${branchName}');

		return macro $v{branchName};
		#else

		var branchName:String = "";
		return macro $v{branchName};
		#end
	}

	public static macro function getGitHasLocalChanges():haxe.macro.Expr.ExprOf<Bool> {
		#if !display
		var pos = haxe.macro.Context.currentPos();
		var branchProcess = new sys.io.Process('git', ['status', '--porcelain']);

		if (branchProcess.exitCode() != 0) {
			var message = branchProcess.stderr.readAll().toString();
			haxe.macro.Context.info('[WARN] Could not determine current git commit; is this a proper Git repository?', pos);
		}

		var output:String = '';
		try {
			output = branchProcess.stdout.readLine();
			branchProcess.close();
		} catch (e) {
			if (e.message == 'Eof') {
			} else {
				throw e;
			}
		}
		trace('Git Status Output: ${output}');

		return macro $v{output.length > 0};
		#else
		return macro $v{true};
		#end
	}
}
