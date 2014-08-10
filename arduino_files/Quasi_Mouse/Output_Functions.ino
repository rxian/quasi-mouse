/* Bluetooth Functions  */
void bluetoothLoop() {  // constantly check for new events from nRF8001
  // check the status of the bluetooth module
  BTLEserial.pollACI();
  aci_evt_opcode_t bluetoothStatus = BTLEserial.getState();
  if (bluetoothStatus != bluetoothLaststatus) {  // If the status changed....
    if (bluetoothStatus == ACI_EVT_DEVICE_STARTED) {
      #ifdef DEBUG_SERIAL
      Serial.println(F("* Advertising started"));  // print it out!
      #endif
      wtv020sd16p.stopVoice();
      motorStop();
      motorASpeed = 255;
      motorBSpeed = 255;
    }
    if (bluetoothStatus == ACI_EVT_CONNECTED) {
      #ifdef DEBUG_SERIAL
      Serial.println(F("* Connected!"));
      #endif
      lastBattCheck = millis() - 1000;
    }
    if (bluetoothStatus == ACI_EVT_DISCONNECTED) {  // this function might not be called, because it skips to broadcasting state
      #ifdef DEBUG_SERIAL
      Serial.println(F("* Disconnected or advertising timed out"));
      #endif
      wtv020sd16p.stopVoice();
      motorStop();
      motorASpeed = 255;
      motorBSpeed = 255;
    }
    bluetoothLaststatus = bluetoothStatus;  // OK set the last status change to this one
  }

  if (bluetoothStatus == ACI_EVT_CONNECTED) {
    // check and send battery information
    if (lastBattCheck + 10000 <= millis()) {
      #ifdef DEBUG_SERIAL
      Serial.println(analogRead(BATT_INDICATOR));
      #endif
      String s = String(analogRead(BATT_INDICATOR));
      uint8_t sendbuffer[20];
      s.getBytes(sendbuffer, 20);
      char sendbuffersize = min(20, s.length());
      BTLEserial.write(sendbuffer, sendbuffersize);
      lastBattCheck = millis();
    }
    
    // check if there's new data from the bluetooth module 
    if (BTLEserial.available()) {
      #ifdef DEBUG_SERIAL
      Serial.print("* "); Serial.print(BTLEserial.available()); Serial.println(F(" bytes available from BTLE"));
      #endif
      
      String actionType = "";  // this will store the first letter from the incoming data, to identify the action type
      boolean isFirstChar = true;  // this will tell the following program whether the incoming letter is the first data
      String actionValueStr = "";  // this will store the value of that action
      int actionValue = 0;  // this will store the value of that action, in integer

      while (BTLEserial.available()) {  // process incoming data
        char temp = BTLEserial.read();
        if(isFirstChar) {  // if this is the first character
          actionType += temp;  // save the action type charater
          isFirstChar = false;
        } else {
          actionValueStr +=temp;  // save the action value string
        }
      }
      actionValue = actionValueStr.toInt();  // convert the action value string to integer
      
      #ifdef DEBUG_SERIAL
      Serial.println(actionType);
      Serial.println(actionValue);
      #endif
      
      if (actionType == "A") {  // if action is to specify motor A speed 
        doMove(actionValue, 1);
      } else if (actionType == "B") {  // if action is to specify motor B speed
        doMove(actionValue, 2);
      } else if (actionType == "S") {  // if action is to play the sound
        doPlay(actionValue);
      } else if (actionType == "I") {  // if action is to adjust the volume
        doVolume(actionValue);
      }
    }
  }
}


/*  Motor Functions  */
void doMove(int actionValue, int motor) {
  int motorDirectForwardSpeed;
  int motorDirection = 0;
  if (actionValue > 255) {
      motorDirectForwardSpeed = actionValue - 255;
      motorDirection = 1;
  } else {
      motorDirectForwardSpeed = 255 - actionValue;
  }
  if (motor == 1) {
    motorASpeed = actionValue;
  } else {
    motorBSpeed = actionValue;
  }
  if (motorASpeed == 255 && motorBSpeed == 255) {
    motorStop();
  }
  motorMove(motorDirectForwardSpeed, motorDirection, motor);
}

void motorMove(int motorSpeed, int motorDirection, int motor) {
  digitalWrite(MOTOR_STBY, HIGH);  // disable standby
  boolean inPin1 = HIGH;  // direction determine for motor A
  boolean inPin2 = LOW;
  if (motorDirection == 1) {
    inPin1 = LOW;
    inPin2 = HIGH;
  }
  if (motor == 1) {
    digitalWrite(MOTOR_AIN1, inPin1);
    digitalWrite(MOTOR_AIN2, inPin2);
    analogWrite(MOTOR_PWMA, motorSpeed);
  } else {
    digitalWrite(MOTOR_BIN1, inPin1);
    digitalWrite(MOTOR_BIN2, inPin2);
    analogWrite(MOTOR_PWMB, motorSpeed);
  }
  #ifdef DEBUG_SERIAL
  Serial.print("motor A: ");
  Serial.print(motorASpeed);
  Serial.print("motor B: ");
  Serial.println(motorBSpeed);
  #endif
}

void motorStop() {
  digitalWrite(MOTOR_STBY, LOW);  // enable standby  
}


/*  Sound Functions  */
void doPlay(int fileNumber) {
  wtv020sd16p.stopVoice();
  delay(10);  // increased stability
  wtv020sd16p.asyncPlayVoice(fileNumber);
}

void doVolume(int volume) {
  if (volume == 1) {
    wtv020sd16p.asyncPlayVoice(0XFFF1);  // volumn control, from 0XFFF0 to 0xFFF7
  } else if (volume == 2) {  // too lazy to use smart ways
      wtv020sd16p.asyncPlayVoice(0XFFF2);  // volumes below 0xFFF4 are unstable
  } else if (volume == 3) {
      wtv020sd16p.asyncPlayVoice(0XFFF3);
  } else if (volume == 4) {
      wtv020sd16p.asyncPlayVoice(0XFFF4);
  } else if (volume == 5) {
      wtv020sd16p.asyncPlayVoice(0XFFF5);
  } else if (volume == 6) {
      wtv020sd16p.asyncPlayVoice(0XFFF6);
  } else if (volume == 7) {
      wtv020sd16p.asyncPlayVoice(0XFFF7);
  }
}
