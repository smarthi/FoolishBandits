from abc import ABC, abstractmethod
import numpy as np

class BanditPolicy(ABC):
    @abstractmethod
    def choose(self, x):
        pass

    @abstractmethod
    def update(self, x, a, r):
        pass

    def chosen_action(self, chosen_action):
        return ()[chosen_action]

    def action_arm_dict(self, arm):
        return {"low": 0, "medium": 1, "high": 2}[arm]


class LinUCB(BanditPolicy):
    def __init__(self, n_arms, features, alpha=1.0):
        """
        This is Linear UCB implementation based on below paper
        See Algorithm 1 from paper:
                "A Contextual-Bandit Approach to Personalized News Article Recommendation"
                https://arxiv.org/pdf/1003.0146
        Args:
                n_arms (int): the number of different arms/ actions the algorithm can take
                features (list of str): contains the patient features to use
                alpha (float): hyperparameter for step size.

        TODO:
                - Please initialize the following internal variables for the Disjoint Linear UCB Bandit algorithm:
                        * self.n_arms
                        * self.features
                        * self.d
                        * self.alpha
                        * self.A
                        * self.b
                  These terms align with the paper, please refer to the paper to understand what they are.
                  Feel free to add additional internal variables if you need them, but they are not necessary.
        """
        self.n_arms = n_arms
        self.features = features
        self.alpha = alpha
        self.d = len(features)
        self.A = [np.eye(self.d) for _ in range(n_arms)]
        self.b = [np.zeros(self.d) for _ in range(n_arms)]

    def choose(self, x):
        """
        See Algorithm 1 from paper:
                "A Contextual-Bandit Approach to Personalized News Article Recommendation"

        Args:
                x (dict): Dictionary containing the possible patient features.
        Returns:
                output (str): string containing one of ('low', 'medium', 'high')
        """
        xvec = np.array([x[f] for f in self.features])
        theta_hat = np.linalg.solve(self.A, self.b)
        # Calculate UCB for each arm
        ucb_values = {arm: theta_hat[arm].dot(xvec) + self.alpha * np.sqrt(xvec.dot(np.linalg.solve(self.A[arm], xvec))) for arm in range(self.n_arms)}

        # Choose the arm with the maximum UCB value
        chosen_arm = max(ucb_values, key=ucb_values.get)
        return self.chosen_action(chosen_arm)

    def update(self, x, a, r):
        """
        See Algorithm 1 from paper:
                "A Contextual-Bandit Approach to Personalized News Article Recommendation"

        Args:
                x (dict): Dictionary containing the possible patient features.
                a (str): string, indicating the action your algorithm chose ('low', 'medium', 'high')
                r (int): the reward you received for that action
        """
        xvec = np.array([x[f] for f in self.features])
        action = self.action_arm_dict(a)
        self.A[action] += np.outer(xvec, xvec)
        self.b[action] += r * xvec

class ThomSampB(BanditPolicy):
    def __init__(self, n_arms, features, alpha=1.0):
        """
        This implementation is based on Algorithm 1 and section 2.2 from paper:
                "Thompson Sampling for Contextual Bandits with Linear Payoffs"
                https://arxiv.org/pdf/1209.3352

        Args:
                n_arms (int): the number of different arms/ actions the algorithm can take
                features (list of str): contains the features to use
                alpha (float): hyperparameter for step size.

        Hints:
                - We keep track of a separate B, mu, f for each action (this is what the Disjoint in the algorithm name means)
                - Unlike in section 2.2 in the paper where they sample a single mu_tilde, we'll sample a mu_tilde for each arm
                        based on our saved B, f, and mu values for each arm. Also, when we update, we only update the B, f, and mu
                        values for the arm that we selected
                - What the paper refers to as b in our case is the features vector
                - The paper uses a summation (from time =0, .., t-1) to compute the model parameters at time step (t),
                        however if you can't access prior data how might one store the result from the prior time steps.


        TODO:
                - initialize the following internal variables for the Thompson sampling bandit algorithm:
                        * self.n_arms
                        * self.features
                        * self.d
                        * self.v2 (please set this term equal to alpha)
                        * self.B
                        * self.mu
                        * self.f
                These terms align with the paper, please refer to the paper to understand what they are.
                Please feel free to add additional internal variables if you need them, but they are not necessary.

        """
        self.v2 = alpha
        self.n_arms = n_arms
        self.features = features
        self.d = len(features)
        self.B = {arm: np.eye(self.d) for arm in range(n_arms)}
        self.mu = {arm: np.zeros(self.d) for arm in range(n_arms)}
        self.f = {arm: np.zeros(self.d) for arm in range(n_arms)}

    def choose(self, x):
        """
        See Algorithm 1 and section 2.2 from paper:
                "Thompson Sampling for Contextual Bandits with Linear Payoffs"

        Args:
                x (dict): Dictionary containing the possible patient features.
        Returns:
                output (str): string containing one of ('low', 'medium', 'high')
        """
        xvec = np.array([x[f] for f in self.features])
        sampled_mu = {arm: np.random.multivariate_normal(self.mu[arm], self.v2 * np.linalg.inv(self.B[arm])) for arm in range(self.n_arms)}
        chosen_action = max(sampled_mu, key=lambda k: sampled_mu[k].dot(xvec))
        return self.chosen_action(chosen_action)

    def update(self, x, a, r):
        """
        See Algorithm 1 and section 2.2 from paper:
                "Thompson Sampling for Contextual Bandits with Linear Payoffs"

        Args:
                x (dict): Dictionary containing the possible patient features.
                a (str): string, indicating the action your algorithem chose ('low', 'medium', 'high')
                r (int): the reward you recieved for that action
        """
        xvec = np.array([x[f] for f in self.features])
        action = self.action_arm_dict(a)
        self.B[action] += np.outer(xvec, xvec)
        self.f[action] += r * xvec
        self.mu[action] = np.linalg.solve(self.B[action], self.f[action])