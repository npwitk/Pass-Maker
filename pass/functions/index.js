const functions = require("firebase-functions");
const { PKPass } = require("passkit-generator");
const admin = require("firebase-admin");
var fs = require('file-system');
var path = require('path');
var axios = require('axios');

// Init
admin.initializeApp();
var storageRef = admin.storage().bucket()

function hexToRgb(hex) {
    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return "rgb(" + parseInt(result[1], 16).toString() + ", " + parseInt(result[2], 16).toString() + ", " + parseInt(result[3], 16).toString() + ")"
}

exports.pass = functions.https.onRequest((request, response) => {
    PKPass.from({
        model: "./model/tu.pass",
        certificates: {
            wwdr: fs.fs.readFileSync("./certs/wwdr.pem"),
            signerCert: fs.fs.readFileSync("./certs/signerCert.pem"),
            signerKey: fs.fs.readFileSync("./certs/signerKey.pem"),
            signerKeyPassphrase: "Google@26"
        },
    },
        {
            authenticationToken: "21973y18723y12897g31289yge981y2gd89ygasdqs12wq",
            webServiceURL: "https://us-central1-npwitk-passmaker.cloudfunctions.net/pass",
            serialNumber: "PASS-213213",
            description: "test description pass",
            logoText: "logoText description",
            foregroundColor: hexToRgb("#" + request.body.textColor),
            backgroundColor: hexToRgb("#" + request.body.backgroundColor)
        })
        .then(async (newPass) => {
            newPass.primaryFields.push(
                {
                    key: "primary",
                    label: request.body.primary.label,
                    value: request.body.primary.value,
                }
            )
            newPass.secondaryFields.push(
                {
                    key: "secondary0",
                    label: request.body.secondary[0].label,
                    value: request.body.secondary[0].value,
                },
                {
                    key: "secondary1",
                    label: request.body.secondary[1].label,
                    value: request.body.secondary[1].value,
                }
            )
            newPass.auxiliaryFields.push(
                {
                    key: "auxiliary0",
                    label: request.body.auxiliary[0].label,
                    value: request.body.auxiliary[0].value,
                },
                {
                    key: "auxiliary1",
                    label: request.body.auxiliary[1].label,
                    value: request.body.auxiliary[1].value,
                }
            )
            newPass.setBarcodes({
                message: request.body.qrText,
                format: "PKBarcodeFormatQR",
                messageEncoding: "iso-8859-1",
            })

            const resp = await axios.get(request.body.thumbnail, { responseType: 'arraybuffer' })
            const buffer = Buffer.from(resp.data, "utf-8")
            newPass.addBuffer("thumbnail.png", buffer)
            newPass.addBuffer("thumbnail@2x.png", buffer)
            const bufferData = newPass.getAsBuffer();
            // fs.writeFileSync("newPass.pkpass", bufferData)
            storageRef.file("passes/custom.pkpass")
                .save(bufferData, (error) => {
                    if (!error) {
                        console.log("Pass was uploaded successfully.");
                        response.status(200).send({
                            "pass": request.body,
                            "status": "Pass successfully generated on server. Love",
                            "result": "SUCCESS",
                        });
                    }
                    else {
                        console.log("Error Uploading pass " + error);
                        response.send({
                            "explanation": error.message,
                            "result": "FAILED",
                        });
                    }
                })
        })
});
