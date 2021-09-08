# %%
import numpy as np
import gpboost as gpb
import matplotlib.pyplot as plt

# %% Simulate Gaussian Process
'''
training and test data 
the latter on a grid for visualization
Tutorial from:
https://htmlpreview.github.io/?https://github.com/fabsig/GPBoost/blob/master/examples/GPBoost_demo.html
'''

# %%
np.random.seed(42)

sigma2_1 = 0.35  # marginal variance of Gaussian Process
rho = 0.1  # range of parameter
sigma2 = 0.1  # error variance
n_train = 200  # number of training samples
n_test = 50  # test data : number of grid points on each axis

# %% training locations
# column_stack: take a sequence of 1-D arrays
# and stack them as columns to make a single 2-D array.
coords = np.column_stack(
    (np.random.uniform(size=1)/2, np.random.uniform(size=1)/2))
print(coords)
while coords.shape[0] < n_train:
    coord_i = np.random.uniform(size=2)
    print(coord_i)
    if not (coord_i[0] >= 0.6 and coord_i[1] >= 0.6):
        coords = np.vstack((coords, coord_i))
        print(coords)
# %% test locations (rectangular grid)
s_1 = np.ones(n_test * n_test)
s_2 = np.ones(n_test * n_test)

for i in range(n_test):
    for j in range(n_test):
        s_1[i * n_test + i] = (i + 1) / n_test
        s_2[i * n_test + j] = (i + 1) / n_test
coords_test = np.column_stack((s_1, s_2))

# %%
# total number of data points
n_all = n_test ** 2 + n_train  # why are n_test squared?
coords_all = np.vstack((coords_test, coords))
D = np.zeros((n_all, n_all))

for i in range(0, n_all):
    for j in range(0, n_all):
        D[i, j] = np.linalg.norm(coords_all[i, :] - coords_all[j, :])
        D[j, i] = D[i, j]

Sigma = sigma2_1 * np.exp(-D / rho) + np.diag(np.zeros(n_all) + 1e-10)
C = np.linalg.cholesky(Sigma)
b_all = C.dot(np.random.normal(size=n_all))
b = b_all[(n_test*n_test):n_all]  # training data Gaussian Process

# %% Mean function
# Use 2 predictor variables of which only one has
# an effect for easy visualization


def f1d(x):
    sin_x = np.sin(3*np.pi*x)
    x_calc = (1 + 3 * np.maximum(np.zeros(len(x)), x-0.5)/(x-0.5)) - 3
    return sin_x + x_calc


# %%
X = np.random.rand(n_train, 2)
F_x = f1d(X[:, 0])  # mean??

xi = np.sqrt(sigma2)
y = F_x + b + xi

# %% test data
x = np.linspace(0, 1, n_test**2)
x[x == 0.5] = 0.5 + 1e-10
x_test = np.column_stack((x, np.zeros(n_test**2)))
y_test = f1d(x_test[:, 0]) + b_all[0:(n_test**2)]

# %% chk
plt.scatter(X[:, 0], F_x)
plt.scatter(X[:, 0], y)
# %% training
