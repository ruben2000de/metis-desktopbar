import QtQuick
import QtTest
import "../package/contents/ui/vendor/kurve/components" as Backend

Item {
    width: 240
    height: 42
    Backend.ProcessMonitor { id: backend }
    TestCase {
        name: "NativeProcessAdapter"
        when: windowShown
        function init() {
            if (backend.loadingFailed) skip("Optional native process extension is not installed")
            backend.stop()
        }
        function cleanup() { backend.stop() }
        function test_start_executes_the_configured_command() {
            backend.command = "printf 'metis-native-fixture\\n'"
            backend.start()
            tryVerify(function() { return backend.stdout.trim() === "metis-native-fixture" }, 3000)
        }
        function test_restart_and_stop_own_process() {
            backend.command = "exec sleep 3"
            backend.restart()
            tryCompare(backend, "running", true, 1500)
            backend.stop()
            tryCompare(backend, "running", false, 1500)
        }
    }
}
