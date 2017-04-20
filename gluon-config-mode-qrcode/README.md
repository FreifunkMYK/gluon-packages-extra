# gluon-config-mode-qrcode

This module adds an QR-Code to the config-mode reboot page. It can be used to register a node on your communities website. URL can be configured using site.conf. Adds ~25kb of code.

## Configuration
First include the code into your local module repository and add ``gluon-config-mode-qrcode`` to ``GLUON_SITE_PACKAGES`` in ``site.mk``. Now add the following parameters to your ``site.conf``:

      config_mode = {
        qrcode = {
          show_qrcode = true,
          url_prefix = 'https://www.freifunk-myk.de/node/add?'
          url_suffix = '&amp;action=register'
        }
      }

The parameters ``show_qrcode`` and ``url_prefix`` are mandatory, ``url_suffix`` can be omitted. The script will automatically add the following parameters: ``mac=**MAC**&key=**KEY**&host=**HOSTNAME**&contact=**CONTACT**`` so using the sample configuration above will generate a QR-code containing the following URL:

``https://www.freifunk-myk.de/node/add?mac=52%3A54%3A00%3A12%3A34%3A56&key=12345678901234567890123456789012345678901234567890123456789012&host=ffmyk%2D525400123456&contact=testcontact``

## Original Idea
* The Code is based on [QRCodeJS](https://github.com/davidshimjs/qrcodejs) by [Sangmin, Shim](https://github.com/davidshimjs).
* Data fields are encoded using [urlencode by ignisdesign](https://gist.github.com/ignisdesign/4323051).
* The [first gluon-implementation](https://github.com/freifunk-gluon/gluon/pull/613) was created by [Flip](https://github.com/Philhil) of [Freifunk Stuttgart](https://freifunk-stuttgart.de/).
* Rewritten as a module by [Florian Knodt](https://adlerweb.info) of [Freifunk Mayen-Koblenz](https://www.freifunk-myk.de)

## Notes
* Currently a pre-[minified](https://jscompress.com/) version of qrcode.js is supplied in the files/-folder. The original code can be found in jssrc/
* The code has only been tested with fastd based setups

## Todo

There is currently no active development besides keeping the code running. If you are willing to modify the code you might want to consider the following changes. Pull-Requests are of course highly welcome.

* Use internal js-minification
* Check if there are smaller JS-based QR-Generators
* Adapt to other VPN types
