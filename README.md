# GFLiveScanner

Import this package to perform live scanning of barcodes, QR codes and OCR.
GFLiveScannerViewController is the one you have to present in order to perform a live scan. 
You can configure the view controller to be full screen or to have a toolbar with a close button. Please refer to GFLiveScannerOptions for providing configuration to the view controller.

It is also possible to use the OCR on an existing image by calling GFOcrHelper instad of instantiating the GFLiveScannerViewController. 
GFOcrHelper uses [Vision](https://developer.apple.com/documentation/vision) and can be configure for fast scanning (set by the view controller when using the live OCR). If you provide an image, I suggest setting fast scanning to false to improve accuracy.

See [this project](https://github.com/gualtierofrigerio/OCRTest) for examples on how to use the live scanner for barcodes and OCR and to provide images to GFOcrHelper to perfor OCR.
