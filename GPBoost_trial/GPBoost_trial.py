# %%
import numpy as np
import gpboost as gpb
import shap  # Numba requires numpy version <= 1.20
import matplotlib.pyplot as plt

# %% Simulate Gaussian Process
'''
training and test data 
the latter on a grid for visualization
Tutorial from:
https://htmlpreview.github.io/?https://github.com/fabsig/GPBoost/blob/master/examples/GPBoost_demo.html
'''
np.random.seed(1)
# %%
sigma2_1 = 0.35  # marginal variance of Gaussian Process
rho = 0.1  # range of parameter
sigma2 = 0.1  # error variance
n_train = 200  # number of training samples
n_test = 50  # test data : number of grid points on each axis

# %% training locations
# column_stack: take a sequence of 1-D arrays
# and stack them as columns to make a single 2-D array.
coords_train = np.column_stack(
    (np.random.uniform(size=1)/2, np.random.uniform(size=1)/2))
# print(coords_train)

while coords_train.shape[0] < n_train:
    coord_i = np.random.uniform(size=2)
    # print(coord_i)
    if not (coord_i[0] >= 0.6 and coord_i[1] >= 0.6):
        coords_train = np.vstack((coords_train, coord_i))
        # print(coords_train)
# %% test locations (rectangular grid)
s_1 = np.ones(n_test * n_test)
s_2 = np.ones(n_test * n_test)

for i in range(n_test):
    for j in range(n_test):
        s_1[j * n_test + i] = (i + 1) / n_test
        s_2[i * n_test + j] = (i + 1) / n_test
coords_test = np.column_stack((s_1, s_2))

# %%
# total number of data points
n_all = n_test ** 2 + n_train  # why are n_test squared?
coords_all = np.vstack((coords_test, coords_train))
D = np.zeros((n_all, n_all))  # distance matrix

# calc distance
for i in range(0, n_all):
    for j in range(0, n_all):
        D[i, j] = np.linalg.norm(coords_all[i, :] - coords_all[j, :])
        D[j, i] = D[i, j]

Sigma = sigma2_1 * np.exp(-D / rho) + np.diag(np.zeros(n_all) + 1e-10)
C = np.linalg.cholesky(Sigma)
b_all = C.dot(np.random.normal(size=n_all))
b_train = b_all[(n_test*n_test):n_all]   # training data Gaussian Process
b_test = b_all[0:(n_test*n_test)]        # test data Gaussian Proccess
# %% Mean function
# Use 2 predictor variables of which only one has
# an effect for easy visualization


def f1d(x):
    sin_x = np.sin(3*np.pi*x)
    x_calc = (1 + 3 * np.maximum(np.zeros(len(x)), x-0.5)/(x-0.5))
    output = sin_x + x_calc - 3
    return output


# %% train_data
x_train = np.random.rand(n_train, 2)
F_x = f1d(x_train[:, 0])  # mean
xi = np.sqrt(sigma2) * np.random.normal(size=n_train)  # simulate error term
y = F_x + b_train + xi  # observed data

# %% test data(generate like train)
x_test = np.random.rand(n_test*n_test, 2)
F_x_test = f1d(x_test[:, 0])
xi_test = np.sqrt(sigma2) * np.random.normal(size=n_test*n_test)
y_test = F_x_test + b_test + xi_test

# %% chk
plt.scatter(x_train[:, 1], y)
plt.scatter(x_train[:, 0], y)

# %%
plt.scatter(x_test[:, 1], y_test)
plt.scatter(x_test[:, 0], y_test)
# %% training
gp_model = gpb.GPModel(gp_coords=coords_train, cov_function="exponential")
data_train = gpb.Dataset(x_train, y)
params = {
    'objective': 'rmse',
    'learning_rate': 0.01,
    'max_depth': 3,
    'min_data_in_leaf': 10,
    'num_leaves': 2**10,
    'verbose': -1
}

bst = gpb.train(params=params, train_set=data_train,
                gp_model=gp_model, num_boost_round=247)
print('estimated covariance parameters')
gp_model.summary()
# %% predict
pred = bst.predict(data=x_test,
                   gp_coords_pred=coords_test,
                   predict_var=True)
y_pred = pred['fixed_effect'] + pred['random_effect_mean']
print("Mean square error (MSE): " + str(np.mean((y_pred-y_test)**2)))
# Mean square error (MSE): 0.3942885572834001
# my env: Mean square error (MSE): 0.6205247584612723
# %%
plt.scatter(y_pred, y_test)
# %%

shap_values = shap.TreeExplainer(bst).shap_values(x_train)
shap.summary_plot(shap_values, x_train)
# %%
shap.dependence_plot("Feature 0", shap_values, x_train)
