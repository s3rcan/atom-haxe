package utils;

import js.node.ChildProcess as NodeProcess;
import js.Node.process;

import utils.Promise;

typedef ExecResult = {
    var out: String;
    var err: String;
    var code: Int;
}

typedef ExecOptions = {
    @:optional var cwd: String;
}

    /** Utility to run a command with arguments. */
class Exec {

    private static function __init__() {
            // OS X El Capitan fix (for now)
        if (process.platform == 'darwin') {
            untyped process.env.PATH = "/usr/local/bin:" + process.env.PATH;
        }
    } //__init__

        /** Runs a shell command with args, returning a promise that will resolve with {out, err, code}
            The promise does not reject.
            Pass the ondataout and ondataerr handlers to get incremental changes
            (this doesn't change the above behavior) */
    public static function run(cmd:String, args:Array<String>, ?options:ExecOptions, ?ondataout:String->Void, ?ondataerr:String->Void):Promise<ExecResult> {

        return new Promise<ExecResult>(function(resolve, reject) {
                // Configure
            var total_err = "";
            var total_out = "";
            var spawn_options:Dynamic = {cwd: process.cwd()};
            if (options != null) {
                if (options.cwd != null) spawn_options.cwd = options.cwd;
            }

                // Spawn process
            var proc = NodeProcess.spawn(cmd, args, spawn_options);

            proc.stdout.on('data', function(data) {
                var s = Std.string(data);
                total_out += s;
                if (ondataout != null) ondataout(s);
            });

            proc.stderr.on('data', function(data) {
                var s = Std.string(data);
                total_err += s;
                if (ondataerr != null) ondataerr(s);
            });

            proc.on('close', function(code) {
                resolve({
                    out: total_out,
                    err: total_err,
                    code: code
                });
            });
        });

    } //run

}
