import websocket
import json


def test(ws):
    wsMsg = {
        "type": "sender",
        "apikey": "e677ac85fd13a73d9ce55f01615fec43deabe678e652b5721d5aad3108b8eb5b",
    }
    ws.send(json.dumps(wsMsg))
    message = json.loads(ws.recv())

    if message["type"] == "response":
        if message["id"] == "29":
            return True, message["id"]
        else:
            return False, message["id"]
    else:
        # wrong type
        return False, 0
