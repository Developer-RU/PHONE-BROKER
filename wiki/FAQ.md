# FAQ

## Is PHONE BROKER a cloud MQTT service?

No. It is a local broker runtime inside the iOS app.

## Can I run multiple brokers at the same time?

Yes, each broker uses a separate TCP port.

## Does it keep running in background indefinitely?

Not guaranteed. iOS may suspend socket activity.

## Can I export/import broker setup?

Yes. JSON import/export is supported from the app.

## Is this project open source?

Yes, under the MIT license.
