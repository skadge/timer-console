// from: https://developer.tmb.cat/account/applications/1409624939203#
const APP_ID="831fc496"
const APP_KEY="bcf1afe2a4e0d5f2874c5372115106a7"
const TMB_REST_ENDPOINT="https://api.tmb.cat/v1/ibus/"

function request(endpoint, cb) {
    var xhr = new XMLHttpRequest()
    xhr.onreadystatechange = function() {
        //print('xhr: on ready state change: ' + xhr.readyState)
        if(xhr.readyState === XMLHttpRequest.DONE) {
            if(cb) {
                print(xhr.responseText.toString());
                var res = JSON.parse(xhr.responseText.toString())
                cb(res["data"]["ibus"]);

            }
        }
    }
    let req = TMB_REST_ENDPOINT + endpoint + '&app_id=' + APP_ID + '&app_key=' + APP_KEY;
    //print(req);
    xhr.open("GET", req);
    xhr.setRequestHeader('Content-Type', 'application/json')
    xhr.setRequestHeader('Accept', 'application/json')
    xhr.send()
}

function getNextBus(stop_code, lineName, cb) {
    print("Checking next bus for line " + lineName + " at stop "  + stop_code);
    request("lines/" + lineName + "/stops/" + stop_code + "?numberOfPredictions=2", cb)
}
