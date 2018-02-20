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
 프로젝트를 시작하게 되었다. 개인적으로 자율주행 자동차/부품 시뮬레이션 및 검증 시장은 더더욱 확대되지 않을까 생각한다.
 관련 링크 <자율주행 시뮬레이터 start-up cognata>
 http://www.cognata.com/cognata-builds-cloud-based-autonomous-vehicle-simulation-platform-nvidia-microsoft/

 <아직 부족한 점이 많고, 컴알못에 ML 초보, RL은 용어만 들어본 정도라 많이 부끄럾습니다. 공부 하면서 지속적으로 업데이트 해나갈 예정입니다. -같이 논문 쓰시거나 관심 있으신 분들 연락 부탁드립니다>
 