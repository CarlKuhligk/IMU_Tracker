import websocket
import json


def test(ws):
    wsMsg = {
        "type": "sender",
        "apikey": "558fe9f09edca96e6b7007f0c187c30579b0727235b43d58b342faa8f81bb300",
    }
    ws.send(json.dumps(wsMsg))
    message = json.loads(ws.recv())
    result = ""
    if message["type"] == "response":
        if message["id"] == "10":
            result = "type: " + message["type"] + " id: " + message["id"]
            return True, result
        else:
            result = "wrong response-id -> " + message["id"]
            return False, result
    else:
        result = "wrong type -> " + message["type"]
        return False, result
