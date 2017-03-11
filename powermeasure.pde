
#include <Adafruit_ADS1015.h>
#include <Wire.h>
Adafruit_ADS1115 ads(0x48);

double sensorValue0 = 0;  // variable to store the value coming from the sensor
double sensorValue1 = 0;  // variable to store the value coming from the sensor
unsigned long tim1, tim2, now;
unsigned long lasttim, elapsed;
unsigned long lastsec = 0;
double totalPower = 0;
boolean restarted = false;
int counter = 0;
double mAsum = 0;
double Vsum = 0;
double mWuSsum = 0;
double totalSecs = 0;
int numzeros = 0;
double V, mA, mW, mWuS;

void setup() {
  // declare the ledPin as an OUTPUT:
  Serial.begin(9600);
   ads.setGain(GAIN_ONE);
  ads.setSPS(ADS1115_REG_CONFIG_DR_860SPS);
  ads.begin();
  lasttim = micros();

}

void loop() {

  //logic:
  // loop round counting elapsed useconds until 1 second is elapsed.
  // keep a count
  // add up Vs, mAs and use the count to average.
  //
  // add up mWuS over the time (integrate)
  // at the end of the second (or near offer), print out the averages and totalise the mWHs
  // if the mA are zero at any point during the second, then we reset everything and start again (power off device resets)
  // read the value from the sensor:
  tim1 = micros();
  int16_t adc0;  // we read from the ADC, we have a sixteen bit integer as a result
  int16_t adc1;  // we read from the ADC, we have a sixteen bit integer as a result
  adc0 = ads.readADC_SingleEnded(0);
  adc1 = ads.readADC_SingleEnded(1);
  tim2 = micros();

  V = (adc0 * ADS1115_VOLTS_PER_BIT_GAIN_ONE);
  
  
  Vsum += V;
  mA = adc1 * ADS1115_VOLTS_PER_BIT_GAIN_ONE * 1000;
  
  mAsum += mA;
  mW = mA * V;
  mWuS = mW * elapsed;
  mWuSsum += mWuS;
  
  if (mA <= 0) numzeros++; else numzeros=0;
  if (numzeros > 2) // more than 10 zero samples in a row 
  {
    Vsum = 0;
    mAsum = 0;
    counter = 0;
    mWuSsum = 0;
    totalPower = 0;
    totalSecs = 0;
    lastsec = 0;
    numzeros = 0;
  }
  else
  {
    counter++;
    now = (tim1 + tim2) / 2; // average time of the two readings.
    elapsed = now - lasttim;
    lastsec += elapsed;
    lasttim = now;



    if (lastsec > 1000000) {
      // end of our second
      double avgV = Vsum / counter;
      double avgmA = mAsum / counter;
      double mWH = mWuSsum / 3600000000; // divide by uS / H
      totalPower += mWH;
      totalSecs += lastsec;

      Serial.print(counter);
      Serial.print(" V: ");
      Serial.print(avgV, 7);
      Serial.print(" mA: ");
      Serial.print(avgmA, 7);
      Serial.print(" mW: ");
      Serial.print(avgV * avgmA, 7);
      Serial.print(" P: ");
      Serial.print(totalPower,7);
      Serial.print(" S: ");
      Serial.print(totalSecs / 1000000);

      Serial.println();

      Vsum = 0;
      mAsum = 0;
      counter = 0;
      mWuSsum = 0;

      lastsec = 0;
    }
  }
}
