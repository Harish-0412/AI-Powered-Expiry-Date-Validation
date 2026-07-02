import urllib.request
import json
import urllib.parse

def test_api(query: str):
    url = f"http://127.0.0.1:8002/api/v1/products/search?query={urllib.parse.quote(query)}"
    print(f"\n=== Testing: '{query}' ===")
    try:
        req = urllib.request.urlopen(url)
        res = json.loads(req.read())
        print(json.dumps(res, indent=2, default=str))
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"HTTP {e.code}: {body}")
    except Exception as e:
        print(f"Connection Error: {e}")

test_api("8901262010011")   # Barcode
test_api("Amul")            # Name
test_api("AMUL-TAAZA-500ML") # SKU
test_api("8909999999999")   # Unknown barcode
test_api(" ")               # Invalid/empty
