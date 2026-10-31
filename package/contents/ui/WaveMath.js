function isSafeMonitorSource(source) {
    // This is PulseAudio's reserved alias for the default sink's monitor.
    // Device names are not accepted: a .monitor suffix alone proves no type.
    return source === "@DEFAULT_MONITOR@"
}

function shouldRunAudio(playerReady, playbackStatus, playingStatus, monitorSource) {
    return playerReady === true
        && playbackStatus === playingStatus
        && isSafeMonitorSource(monitorSource)
}

function musicClickAction(playerReady) {
    return playerReady === true ? "popup" : "launch"
}

function interpolate(values, targetCount, maxValue) {
    if (!values || typeof values.length !== "number") {
        return []
    }

    var count = Math.floor(Number(targetCount))
    if (!isFinite(count) || count < 2) {
        return []
    }
    count = Math.min(count, 256)

    var ceiling = Number(maxValue)
    if (!isFinite(ceiling) || ceiling <= 0) {
        ceiling = 100
    }

    var clean = []
    for (var i = 0; i < values.length; i++) {
        var value = Number(values[i])
        if (!isFinite(value)) {
            continue
        }
        clean.push(Math.max(0, Math.min(ceiling, value)))
    }
    if (clean.length === 0) {
        return []
    }

    var result = []
    if (clean.length === 1) {
        for (var single = 0; single < count; single++) {
            result.push(clean[0])
        }
        return result
    }

    for (var point = 0; point < count; point++) {
        var position = (clean.length - 1) * point / (count - 1)
        var left = Math.floor(position)
        var right = Math.min(clean.length - 1, left + 1)
        var fraction = position - left
        result.push(clean[left] + (clean[right] - clean[left]) * fraction)
    }
    return result
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        isSafeMonitorSource: isSafeMonitorSource,
        shouldRunAudio: shouldRunAudio,
        musicClickAction: musicClickAction,
        interpolate: interpolate
    }
}
