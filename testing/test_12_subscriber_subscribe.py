import websocket
import json


def test(ws):
    wsMsg = {"type": "subscribe", "channel_id": "16", "subscribe": "true"}
    ws.send(json.dumps(wsMsg))
    message = json.loads(ws.recv())

    if message["type"] == "response":
        if message["id"] == "11":
            return True, message["id"]
        else:
            return False, message["id"]
    else:
        # wrong type
        return False, 0
