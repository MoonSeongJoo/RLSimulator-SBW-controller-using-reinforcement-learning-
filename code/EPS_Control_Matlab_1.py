import argparse
import math
import os
import ctypes

import numpy as np
import random
import socket
import pickle

import tensorflow as tf
import simplejson as json

from keras.models import model_from_json, Model
from keras.models import Sequential
from keras.layers.core import Dense, Dropout, Activation, Flatten
from keras.layers.recurrent import LSTM,GRU
from keras.optimizers import Adam,RMSprop

from ReplayBuffer import ReplayBuffer
from ActorNetwork import ActorNetwork
from CriticNetwork import CriticNetwork
from OU import OU
import timeit

OU = OU()       #Ornstein-Uhlenbeck Process


def gradient_inverter(grads, a_t_inv, p_min, p_max, BATCH_SIZE):
    """Gradient inverting as described in https://arxiv.org/abs/1511.04143"""
    delta = p_max - p_min
    p_max_matrix = p_max *np.ones([BATCH_SIZE,1])
    p_min_matrix = p_min *np.ones([BATCH_SIZE,1])
    grads1 = grads[0][0]
    if delta <= 0:

        raise(ValueError("p_max <= p_min"))
    
    if grads1 >=0 :
       inverted_gradient = (p_max_matrix - a_t_inv) / delta
    else : 
       inverted_gradient = (a_t_inv - p_min_matrix) / delta

    return inverted_gradient


def playGame(train_indicator=1) :    #1 means Train, 0 means simply Run

    BUFFER_SIZE = 100000
    BATCH_SIZE = 30
    GAMMA = 0.99
    TAU = 0.0001     #Target Network HyperParameters
    LRA = 0.00001    #Learning rate for Actor
    LRC = 0.0001     #Lerning rate for Critic

    action_dim = 1  #Steering/Acceleration/Brake
    state_dim = 15  #of sensors input

    np.random.seed(1337)
    vision = False

    EXPLORE = 1000000.
    episode_count = 3000
    max_steps = 1000000
    reward = 0
    done = False
    step = 0
    epsilon = 1
    indicator = 0
    t_dt = 0.0005
    
    #TCP/IP communication for MATLAB - Python
    HOST = '0.0.0.0' 
    PORT = 40000
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 4096)
    s.bind((HOST, PORT))
    #Matlab client waiting
    s.listen(1)
    print ("waiting for response from client at port ",PORT)
    conn, addr = s.accept()
    
    #Tensorflow GPU optimization
    config = tf.ConfigProto()
    config.gpu_options.allow_growth = True
    sess = tf.Session(config=config)

    from keras import backend as K
    K.set_session(sess)

    actor = ActorNetwork(sess, state_dim, action_dim, BATCH_SIZE, TAU, LRA)
    critic = CriticNetwork(sess, state_dim, action_dim, BATCH_SIZE, TAU, LRC)

    buff = ReplayBuffer(BUFFER_SIZE)    #Create replay buffer
  
    #Now load the weight
    print("Now we load the weight")

    try:
        actor.model.load_weights("actormodel.h5")
        critic.model.load_weights("criticmodel.h5")
        actor.target_model.load_weights("actormodel.h5")
        critic.target_model.load_weights("criticmodel.h5")

        print("Weight load successfully")

    except:
        print("Cannot find the weight")
   
    print("TORCS Experiment Start.")
    
    for i in range(episode_count):

        print("Episode : " + str(i) + " Replay Buffer " + str(buff.count()))
        
        total_reward = 0.

        for j in range(max_steps):
            loss = 0 
            epsilon -= 1.0 / EXPLORE
            a_t = np.zeros([1,action_dim])
            noise_t = np.zeros([1,action_dim])
            Lateral = 0
            #Carsim export(input factor) variable catch s_t
            try :
                ob_exports = conn.recv(4096)
            except KeyboardInterrupt :
                #conn.shutdown()
                conn.close()
                break
            ob_exports1 = json.loads(ob_exports.decode('utf-8'))
            print('export=',ob_exports1)
            if not ob_exports: 
                #conn.shutdown()
                conn.close()
                break
            t_current = ob_exports1[0]
            T_bar_Tq = ob_exports1[1]/10
            LatG = ob_exports1[2]
            YawRate = ob_exports1[3]/50
            Yaw = ob_exports1[4]/3.14
            Lateral = ob_exports1[5]/20
            Steer_SW = ob_exports1[6]/6000
            StrAV_SW = ob_exports1[7]/5000
            Steer_L1 = ob_exports1[8]/180
            Steer_R1 = ob_exports1[9]/180
            Steer_L2 = ob_exports1[10]/4
            Steer_R2 = ob_exports1[11]/4
            Xcg_TM = ob_exports1[12]/1000
            Ycg_TM = ob_exports1[13]/300
            Zcg_TM = ob_exports1[14]/45
            curv = ob_exports1[15]
#            print('T_bar_Tq=',T_bar_Tq)
#            print('LatG=',LatG)

            s_t = np.hstack((T_bar_Tq, LatG, YawRate,Yaw,Lateral,Steer_SW,StrAV_SW,Steer_L1,Steer_R1,Steer_L2,Steer_R2,Xcg_TM,Ycg_TM,Zcg_TM,curv))
            print('s_t=',s_t)
            a_t_original = actor.model.predict(s_t.reshape(1, s_t.shape[0]))
            print('a_t_original=',a_t_original)
            print('a_t_original=',a_t_original)
            a_t_inv =a_t_original[0][0]
            print(a_t_inv.shape)
            critic_gradient = critic.gradients(s_t.reshape(1, s_t.shape[0]), a_t_original)
            noise_t[0][0] = train_indicator * max(epsilon, 0) * OU.function(a_t_original[0][0],  0.0 , 0.00, 0.00)
#            noise_t[0][1] = train_indicator * max(epsilon, 0) * OU.function(a_t_original[0][1],  0.5 , 1.00, 0.10)
#            noise_t[0][2] = train_indicator * max(epsilon, 0) * OU.function(a_t_original[0][2], -0.1 , 1.00, 0.05)

            #The following code do the stochastic brake

            #if random.random() <= 0.1:
            #    print("********Now we apply the brake***********")
            #    noise_t[0][2] = train_indicator * max(epsilon, 0) * OU.function(a_t_original[0][2],  0.2 , 1.00, 0.10)

            a_t[0][0] = a_t_original[0][0] + noise_t[0][0]
#            a_t[0][1] = a_t_original[0][1] + noise_t[0][1]
#            a_t[0][2] = a_t_original[0][2] + noise_t[0][2]
            a_t[0][0] = a_t[0][0]*3500
            
            t_current = t_current + t_dt
            print('t_next=',t_current)
            print(a_t[0])
            at= np.array(a_t[0])
#            print("at=",at)
            at1= np.insert(at,0,t_current)
#            print('at1=,',at1)
            at2=list(at1)
            print('at2=,',at2)
            
            #provide action value to matlab
            try:
                at_json = json.dumps(at2)
                a = '\r\n'
                at_json1 = at_json+a
#               print('at_json1',at_json1)
                at_json2 = at_json1.encode('utf-8')
#               print('at_json2',at_json2)
                conn.sendall(at_json2)
            except KeyboardInterrupt:
                #conn.shutdown()
                conn.close()
                break
            
            #Carsim export(input factor) variable catch s_t1
            try:
                ob_exports = conn.recv(4096)
            except KeyboardInterrupt:
                #conn.shutdown()
                conn.close()
                break
            ob_exports1 = json.loads(ob_exports.decode('utf-8'))
            print('s_t1=',ob_exports1)
            if not ob_exports: 
                #conn.shutdown()
                conn.close()
                break
            T_bar_Tq1 = ob_exports1[0]/10
            LatG1 = ob_exports1[1]
            YawRate1 = ob_exports1[2]/50
            Yaw1 = ob_exports1[3]/3.14
            Lateral1 = ob_exports1[4]/20
            Steer_SW1 = ob_exports1[5]/6000
            StrAV_SW1 = ob_exports1[6]/5000
            Steer_L11 = ob_exports1[7]/180
            Steer_R11 = ob_exports1[8]/180
            Steer_L21 = ob_exports1[9]/4
            Steer_R21 = ob_exports1[10]/4
            Xcg_TM1 = ob_exports1[11]/1000
            Ycg_TM1 = ob_exports1[12]/300
            Zcg_TM1 = ob_exports1[13]/45
            curv = ob_exports1[14]
            r_t = ob_exports1[15]
            done = ob_exports1[16]
#            print('T_bar_Tq1=',T_bar_Tq1)
            print('r_t=',r_t)
            
#            if abs(Lateral1) > 1 or abs(Yaw1) > 1 :
            if t_current > 20 or abs(Yaw1) > 1 :
            
                break

            s_t1 = np.hstack((T_bar_Tq1, LatG1, YawRate1,Yaw1,Lateral1,Steer_SW1,StrAV_SW1,Steer_L11,Steer_R11,Steer_L21,Steer_R21,Xcg_TM1,Ycg_TM1,Zcg_TM1,curv))
            buff.add(s_t, a_t[0], r_t, s_t1, done)      #Add replay buffer
            
            #Do the batch update
            batch = buff.getBatch(BATCH_SIZE)
            states = np.asarray([e[0] for e in batch])
            actions = np.asarray([e[1] for e in batch])
            rewards = np.asarray([e[2] for e in batch])
            new_states = np.asarray([e[3] for e in batch])
            dones = np.asarray([e[4] for e in batch])
            y_t = np.asarray([e[1] for e in batch])
           
#            print ("Rewards=",rewards)
#            print ("Actions=",actions)
#            print ("states=",states)
#            print (states.shape)
            
            target_q_values = critic.target_model.predict([new_states, actor.target_model.predict(new_states)])             
#            print("rt1=",target_q_values)
#            print(target_q_values.shape)
            
            for k in range(len(batch)):

                if dones[k]:

                    y_t[k] = rewards[k]

                else:

                    y_t[k] = rewards[k] + GAMMA*target_q_values[k]       

                    
            if (train_indicator):

                loss += critic.model.train_on_batch([states,actions], y_t) 
                a_for_grad = actor.model.predict(states)
#                print("a_for_grad=",a_for_grad)
#                print(a_for_grad.shape)
                grads = critic.gradients(states, a_for_grad)
#                print("grads=",grads)
#                print(grads.shape)
                if step > 30 :
                    grads_factor=gradient_inverter(critic_gradient,a_t_inv,p_min=-1,p_max=1,BATCH_SIZE=30)
                else :
                    grads_factor=1
#                print("grads_factor=",grads_factor)
                grads_factor1 = np.asarray(grads_factor)
                grads3 = grads*grads_factor1
#                print("grads3=",grads3)
                actor.train(states, grads3)
                actor.target_train()
                critic.target_train()

            total_reward += r_t

            s_t = s_t1
        
            print("Episode", i, "t_current", t_current, "Action", a_t, "Reward", r_t, "Loss", loss ,"step", step)

            step += 1
                   
            if done:

                break
        #s.shutdown()
        
        if (train_indicator):

            print("Now we save model")
            actor.model.save_weights("actormodel.h5", overwrite=True)
            with open("actormodel.json", "w") as outfile:

                json.dump(actor.model.to_json(), outfile)

            critic.model.save_weights("criticmodel.h5", overwrite=True)
            with open("criticmodel.json", "w") as outfile:

                json.dump(critic.model.to_json(), outfile)

        print("TOTAL REWARD @ " + str(i) +"-th Episode  : Reward " + str(total_reward))
        print("Total Step: " + str(step))
            
        print("")
#        s.close() # TCP/IP socket close
        
        
    s.close() # TCP/IP socket close
    print("Finish.")


if __name__ == "__main__":

    playGame()

# -*- coding: utf-8 -*-

