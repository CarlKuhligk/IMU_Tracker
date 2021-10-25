import websocket
import json


def test(ws):
    wsMsg = {
        "type": "sender",
        "apikey": "558fe9f09edca96e6b7007f0c187c30579b0727235b43d58b342faa8f81bb300",
    }
    ws.send(json.dumps(wsMsg))
    message = json.loads(ws.recv())

    if message["type"] == "response":
        if message["id"] == "21":
            return True, message["id"]
        else:
            return False, message["id"]
    else:
        # wrong type
        return False, 0
