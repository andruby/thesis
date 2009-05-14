# Laad een lijst getallen in van een textfile en genereert een histogram

data <- scan(file='data/test_mc.txt');
#pdf('/tmp/histogram.pdf'); # output naar pdf
hist(data,breaks=70,col="red",main="Kostenreductie tov. herberekende originele assignment",ylab="Frequentie",xlab="Kostenreductie (%)")
#dev.off()