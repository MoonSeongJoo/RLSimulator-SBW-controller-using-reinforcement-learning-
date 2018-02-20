t = tcpip('127.0.0.1', 50000);
fopen(t);
serverdata='hello server';
fwrite(t, serverdata);
data=fscanf(t);
disp(data);
fclose(t);