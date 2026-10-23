# Table of Contents

## Why divide by 10,000, then subtract by 0.1?
[loadImg.m, line 34](../src/loadImg.m#L34)
It is from the file format.  Reflectance is a fraction between 0 and 1.  ESA stores this as a whole number times 10,000 so its fits into 2-bytes with four decimal places.

The reason to subtract by 0.1 is because values were able to become negative if they were too dark, so they added the offset to prevent it

Sources:
[Multiplied by 10000]()

[Offset +1000](https://forum.step.esa.int/t/info-introduction-of-additional-radiometric-offset-in-pb04-00-products/35431#:~:text=At%20L1C,1000,-SNAP)