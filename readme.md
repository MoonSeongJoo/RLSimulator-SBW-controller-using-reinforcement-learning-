## Steering System Parameter Tuning Using Carsim and Deep Deterministic Policy Gradient

This is python code for comminicating specification of project. (based on yanpanlau github. thaks yanpanlau!!)
So, this code is not perfect of training steering system.
I want to exchange opinions for a better project.

Please read the following blog for details

https://github.com/MoonSeongJoo/MoonSeongJoo.github.io

![](SteeringController1.gif)

# Installation Dependencies:

* Python 3.5
* Keras 2.0.6
* Tensorflow r1.0.0
* CarSim 2017.1
* Matlab R2017a

# How to Run?

```
git clone https://github.com/MoonSeongJoo/RLSimulator-SBW-controller-using-reinforcement-learning-.git
cd code
exection matlab R2017a
python EPS_Control_Matlab_1.py 
run Steer_Control_Moon.m
```

(Change the flag **train_indicator**=1 in EPS_Control_Matlab_1.py if you want to train the network)

# Motivation :
 자율주행에 관심이 많았고, 현재 자동차 steering system 개발을 하고 있기 때문에 자율주행 actuator에 관심이 많았다.
 그러던 중, 머신러닝 강화학습을 배우게 되면서, steering actuator 콘트롤을 강화학습으로 할 수 있지 않을까 하여 
 프로젝트를 시작하게 되었다.

# Background :
 