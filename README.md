# Fast Spike Quality Control (FSQC)
A wave_clus-based algorithm for microwire quality inspection

## Input
Approximately 5 min Neuralynx recording following the standard intracranial nomenclature (XXXu1, XXXu2, etc.) 

## How to use
- Run 'fsqc.m'
- In the first pop-up window (directory selector), select the Neuralynx data directory that contains .ncs files used for quick spike detection (FSQC will automatically select non-empty microwire recordings for each bundle)
- In the second pop-up window (patient name text box), enter patient ID ('TWH' is given by default)
- Lay down and wait a few minutes
- Check results in fsqc/results, most importantly the `<patientID>_fsqc.jpg`

## Note
Depending on the patient's status during recording, data might contain artifacts (e.g., movement). FSQC should only aid the preliminary inspection of microwire data quality.

## Disclaimer
Results are for research purposes only.

## Contact
Qian Chu at qian.chu@mail.utoronto.ca or qian.chu@ae.mpg.de
