package plugin;

import js.node.Path;

import plugin.Plugin;
import build.DefaultBuilder;
import lint.DefaultLinter;
import utils.Log;

import atom.Atom.atom;

import tides.parse.HXML;

class State {

    public var consumer(default,set):Consumer;

    public var hxml(get,null):HXMLInfo;

    public var builder(get,null):Builder;

    public var linter(get,null):Linter;

/// Lifecycle

    @:allow(plugin.Plugin)
    private function new(?serialized_state:Dynamic) {

        if (serialized_state != null) {
            unserialize(serialized_state);
        }

    } //new

    @:allow(plugin.Plugin)
    private function destroy():Void {}

        /** Serialize */
    public function serialize():Dynamic {

            // Put all values we want to keep in the mapping
        var values:Dynamic = {};
        if (consumer != null) {
                // These are the only hxml provider serialized values.
                // Letting us restoring the default hxml provider.
                // It is the responsibility of any external provider
                // To assign itself again on reactivation with additional values
            values.consumer = {
                name: consumer.name,
                hxml: consumer.hxml
            };
        }
        return values;

    } //serialize

        /** Unserialize */
    public function unserialize(values:Dynamic):Void {
            // Update all values on the target state (this)
        if (values.consumer != null && values.consumer.name == 'default') {
                // Reset consumer to default if it was using it before serialization
            consumer = values.consumer;
            Log.success("Active HXML file restored to " + consumer.hxml.file, {display: true});
        }

    } //unserialize

/// Consumer

    private function set_consumer(consumer:Consumer):Consumer {

        return this.consumer = consumer;

    } //set_consumer

    private inline function get_hxml():HXMLInfo {

        return consumer.hxml;

    } //get_hxml

    private function get_builder():Builder {

        if (consumer.builder != null) {
            return consumer.builder;
        } else {
            return DefaultBuilder;
        }

    } //get_builder

    private function get_linter():Linter {

        if (consumer.linter != null) {
            return consumer.linter;
        } else {
            return DefaultLinter;
        }

    } //get_builder

/// Query state

    public function is_valid():Bool {

        if (consumer == null) return false;
        if (consumer.hxml == null) return false;
        if (consumer.hxml.cwd == null) return false;
        if (consumer.hxml.content == null && consumer.hxml.file == null) return false;
        return true;

    } //is_valid

    public function as_args(?plus_args:Array<String>):Array<String> {

        if (!is_valid()) return null;

        var args = [];

        if (hxml.cwd != null) {
            args.push('--cwd');
            args.push(hxml.cwd);
        }

        args = args.concat(hxml_as_args());

        if (plus_args != null) {
            args = args.concat(plus_args);
        }

        return args;

    } //as_args

    public function hxml_as_args():Array<String> {

        if (!is_valid()) return null;

        var args = [];

            // Check if hxml content is set
        if (hxml.content != null) {
                // If not, check if there's a file given instead
            if (hxml.file != null) {
                    // If there is, make it relative
                args = [Path.relative(hxml.cwd, hxml.file)];
            }

        } else {

            args = HXML.parse(hxml.content);

        }

        return args;

    }

}
