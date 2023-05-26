pkg load signal;

%% CONDICIONES DE CONTORNO
bands=16;
bands_per_octave=3;
octaves=9;
low=31.25;
b_bits=14;
a_bits=14;
norm_target=1000;
iir_order=2;
f_samp=48000;
len=20000;
freq_len=65536;
b_fix_range=2^b_bits;
a_fix_range=2^a_bits;

%% CALCULO DE FRECUENCIAS CENTRAL, CORTE ALTA Y CORTE BAJA
fc=(1:bands);
bands=octaves*bands_per_octave + 1;
sep=2^(1/bands_per_octave);
fc(1)=low;

limits=(1:bands+1);
sq_sep=sep^(0.5);
limits(1)=fc(1)/sq_sep;

for i=2:bands
    fc(i)=fc(i-1)*sep;
    limits(i)=fc(i-1)*sq_sep;
end
limits(bands+1)=fc(bands)*sq_sep;



s=zeros(bands,len);
t=1/f_samp:1/f_samp:len/f_samp;
for i=1:bands
    s(i,:)=sin(2*pi*fc(i)*t);
end

s_input=single(s(1,:) + s(5,:) + s(13,:));
c_str=sprintf("static const uint32_t input[%d] = {", len);
c_sep="";
for i=1:len
  c_str=sprintf("%s%s0x%s", c_str, c_sep, num2hex(s_input(i)));
  c_sep=",\r\n  ";
end
c_str=strcat(c_str, "\r\n};");

fc_disc=fc/(f_samp/2);
lim_disc=limits/(f_samp/2);

norm=zeros(bands,1);
b=single(zeros(bands,iir_order+1));
a=single(zeros(bands,iir_order+1));
for i=1:bands
    [bt,at]=butter(iir_order/2, [lim_disc(i) lim_disc(i+1)]);
    b(i,:)=single(bt);
    a(i,:)=single(at);
    norm(i)=norm_target/b(i,1);
end

H_total=zeros(freq_len,1);
figure(1);
for i=1:bands
    [H,Fr]=freqz(b(i,:),a(i,:),freq_len);
    H_total = H_total + abs(H);
    loglog(Fr*f_samp/(2*pi),abs(H));
    hold on;
end
loglog(Fr*f_samp/(2*pi),abs(H_total));
hold off;

c_str=sprintf("%s\r\n\r\nstatic const uint32_t b[%d][%d] = {", c_str, bands, iir_order+1);
c_sep="";
b_str="";
for i=1:bands
  b_sep="\r\n  {";
  coeff_str="";
  for j=1:iir_order+1
    coeff_str=sprintf("%s%s0x%s", coeff_str, b_sep, num2hex(b(i,j)));
    b_sep=", ";
  end
  c_str=strcat(c_str, c_sep, coeff_str, "}");
  c_sep=",";
end
c_str=strcat(c_str,"\r\n};");

c_str=sprintf("%s\r\n\r\nstatic const uint32_t a[%d][%d] = {", c_str, bands, iir_order);
b_str="";
c_sep="";
for i=1:bands
  b_sep="\r\n  {";
  coeff_str="";
  for j=2:iir_order+1
    coeff_str=sprintf("%s%s0x%s", coeff_str, b_sep, num2hex(a(i,j)));
    b_sep=", ";
  end
  c_str=strcat(c_str, c_sep, coeff_str, "}");
  c_sep=",";
end
c_str=strcat(c_str,"\r\n};\r\n");

fd=fopen("iir_coeff.dat", 'w');
fprintf(fd, c_str);
fflush(fd);
fclose(fd);

max_norm=max(norm)*9;
g=zeros(bands,1);
bits_end=floor(log2(max_norm));

b_fix=round(b*b_fix_range);
a_fix=round(a*a_fix_range);

H_total=zeros(freq_len,1);
figure(2);
for i=1:bands
    g(i)=max_norm/norm(i);
  
    [H,Fr]=freqz(g(i)*norm(i)*b_fix(i,:),a_fix(i,:),freq_len);
    H_total = H_total + abs(H);
    loglog(Fr*f_samp/(2*pi),abs(H)/(2^bits_end));
    hold on;
end

loglog(Fr*f_samp/(2*pi),abs(H_total)/(2^bits_end));
hold off;

b_error=round(10000*b_fix./(b*b_fix_range))/100;
a_error=round(10000*a_fix./(a*a_fix_range))/100;
