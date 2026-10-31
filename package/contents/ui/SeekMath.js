function targetPosition(fraction, duration) {
    var f = Number(fraction)
    var d = Number(duration)
    if (!isFinite(f) || !isFinite(d) || d <= 0) return null
    return Math.min(Math.max(0, Math.round(Math.max(0, Math.min(1, f)) * d)), Math.max(0, Math.floor(d) - 1))
}

function formatTime(microseconds) {
    var value = Number(microseconds)
    if (!isFinite(value) || value < 0) return "—:—"
    var seconds = Math.floor(value / 1000000)
    var hours = Math.floor(seconds / 3600)
    var minutes = Math.floor(seconds / 60) % 60
    var rest = seconds % 60
    return (hours > 0 ? hours + ":" + (minutes < 10 ? "0" : "") : "") + minutes + ":" + (rest < 10 ? "0" : "") + rest
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { targetPosition: targetPosition, formatTime: formatTime }
}
