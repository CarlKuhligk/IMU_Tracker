import websocket


def test(wsMaster, wsClient1, wsClient2):
    wsMaster.connect("ws://localhost:8080")
    wsClient1.connect("ws://localhost:8080")
    wsClient2.connect("ws://localhost:8080")
    websocket.enableTrace(True)

    if wsMaster.status == 101 & wsClient1.status == 101 & wsClient2.status == 101:
        return True, 2
    else:
        return False, 1
