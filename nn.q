\c 20 100
\l funq.q
\l mnist.q

/ digit recognition

-1"define a plot function (which includes the empty space character)";
plt:.util.plot[28;14;.util.c10] .util.hmap flip 28 cut
-1"visualize the data";
-1 value (,') over plt each flip  mnist.X[;-4?count mnist.X 0];

-1"we first generate a matrix of y values where each row only has a single 1 value";
-1"the location of which corresponds the the digit in the dataset";

show YMAT:.ml.diag[(1+max mnist.y)#1f]@\:mnist.y

-1"neural networks include multiple layers";
-1"where the first and last are visible, but all others are hidden";
-1"to cost and gradient functions, compute over a list of THETA matrices";
-1"we first define a network topology (the size of each layer)";
-1"it has been proven that a single hidden layer (with enough nodes)";
-1"can approximate any function.  in addition, extra layers add marginal value.";
-1"we present an example with a single hidden layer";
-1"the size of the first and last layer are fixed.";
-1"a good size for the middle layer is the average of the first and last";
n:0N!{(x;(x+y) div 2;y)}[count mnist.X;count YMAT]

-1"correctly picking the initial THETA values is important.";
-1"instead of setting them all to a 0 (or any constant value),";
-1"we must set them to randomn values to 'break the symmetry'.";
-1"additionally, we must chose values that ensure the gradient";
-1"of the sigmoid function is not too small.  .ml.ninit does this";
0N!theta:2 raze/ .ml.ninit'[-1_n;1_n];

l:1                           / lambda (l2 regularization coefficient)
-1"the neural network cost function feeds the X values through the network,";
-1"then backpropagates the errors and gradient for each layer.";
-1"the cost and gradient calculations are expensive but share intermediate values";
-1"it is therefore important to compute both simultaneously";
show .ml.nncostgrad[l;n;mnist.X;YMAT;theta]

-1"in addition, it is important to confirm that the analytic gradient we compute";
-1"is the same (at least to a few significant digits)";
-1"as a discrete (and slower to calculate) gradient.";
(=)."i"$1e8*.ml.checknngradients[.1f;3 5 3]

-1"we can now run (batch) gradient descent across the whole datatset.";
-1"this will always move along the steepest gradient, but makes slow progress";
-1"and is prone to finding local minima";
theta:first .fmincg.fmincg[5;.ml.nncostgrad[l;n;mnist.X;YMAT];theta];

/ NOTE: qml throws a `limit error (too many elements)
/.qml.minx[`quiet`full`iter,1;.ml.nncostgradf[l;n;X;YMAT];enlist theta]
-1"we can, alternatively, perform stochastic gradient descent (SGD).";
-1"by taking a subset of the data on each iteration, we can analyze all the data";
-1"without holding it all in memory simultaneously. in addition, the parameters will";
-1"jump around and therefore increasing the chance we find a global minima.";
-1"SGD converges faster, but might never stop iterating";
-1"";
/https://www.quora.com/Whats-the-difference-between-gradient-descent-and-stochastic-gradient-descent
-1"when the batch size is equal to the size of the data set,";
-1"SGD is equal to batch gradient descent.";
-1"at the other extreme, we can anlayize one observation at a time.";
-1"this is called 'on-line learning'";

-1"we first define a minimization projection:";
mf:{first .fmincg.fmincg[5;.ml.nncostgrad[l;n;mnist.X[;y];YMAT[;y]];x]}
-1"we then have a few choices to randomize the dataset.";
-1"A: permutate, then run n non-permuted epochs";
i:0N?count mnist.X 0
mnist.X:mnist.X[;i];YMAT:YMAT[;i];mnist.Y:mnist.Y[;i];mnist.y:mnist.Y 0
theta:1 .ml.sgd[mf;til;10000;mnist.X]/ theta
-1"B: run n permuted epochs";
theta:1 .ml.sgd[mf;0N?;10000;mnist.X]/ theta
-1"C: run n random (with replacement) epochs (aka bootstrap)";
theta:1 .ml.sgd[mf;{x?x};10000;mnist.X]/ theta

-1"we can run any above example with cost threshold.";
theta:(1f<first .ml.nncostgrad[0f;n;mnist.X;YMAT]@) .ml.sgd[mf;0N?;10000;mnist.X]/ theta

-1"what is the final cost?";
first .ml.nncostgrad[0f;n;mnist.X;YMAT;theta]

-1"how well did we learn on the training data set?";
avg mnist.y=p:.ml.predictonevsall[mnist.X] .ml.nncut[n] theta

-1"we can visualize the hidden features"
plt 1_ rand first .ml.nncut[n] theta

-1"or view a few mistakes"
p w:where not mnist.y=p
do[2;-1 value plt mnist.X[;i:rand w];show ([]p;mnist.y) i]

-1"how well can we predict unseen data";
avg mnist.yt=p:.ml.predictonevsall[mnist.Xt] .ml.nncut[n] theta

-1"or view a few mistakes"
p w:where not mnist.yt=p
do[2;-1 value plt mnist.Xt[;i:rand w];show ([]p;mnist.yt) i]

/ confusion matrix
.util.totals[`TOTAL] .ml.cm[mnist.yt;"i"$p]

