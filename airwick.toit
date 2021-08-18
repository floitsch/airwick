// Copyright (C) 2021 Florian Loitsch. All rights reserved.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the LICENSE file.

/**
Subscribes to the cloud:airwick topic and triggers the spray everytime it
  receives a message.
*/

import gpio
import pubsub
topic ::= "cloud:airwick"

main:
  print "wakeup - checking messages"
  already_sprayed := false
  pubsub.subscribe topic --blocking=false: | msg/pubsub.Message |
    if already_sprayed: continue.subscribe
    already_sprayed = true
    pin := gpio.Pin 18 --output
    pin.set 1
    sleep --ms=700
    pin.set 0
    print "sprayed"
  print "done processing"
