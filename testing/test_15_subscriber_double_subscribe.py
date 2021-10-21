import websocket
import json


def test(ws):
    wsMsg = {"type": "subscribe", "channel_id": "16", "subscribe": "true"}
    ws.send(json.dumps(wsMsg))
    message = json.loads(ws.recv())
    result = ""
    if message["type"] == "response":
        if message["id"] == "24":
            result = "type: " + message["type"] + " id: " + message["id"]
            return True, result
        else:
            result = "wrong response-id -> " + message["id"]
            return False, result
    else:
        result = "wrong type -> " + message["type"]
        return False, result
