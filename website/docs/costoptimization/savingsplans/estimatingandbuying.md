---
title: "Estimating and Purchasing Savings Plans"
sidebar_position: 30
---

Now that you know a bit more about the different types of Savings Plans, you can use the tools in the AWS Cost Management console to recommend potential savings and purchase Savings Plans.

As a prerequisite to getting started with Savings Plans, you'll need to enable Cost Explorer. Cost Explorer helps you optimize your costs with Savings Plans. Start by [enabling your settings and permissions in Cost Explorer](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-enable.html) before using the AWS Billing and Cost Management console to view, analyze, and manage your Savings Plans.  Note that it can take up to 24 hours for the data required to create recommendations to become available.

## Calculating the benefits of Savings Plans
AWS provides customized Savings Plans recommendations based on your past usage so you can save costs. Based on the usage, AWS calculates what your bill could have been if you purchased an additional Savings Plan commitment for that time period. AWS identifies and recommends the commitment value that is estimated to result in the largest monthly savings. Recommendations for Compute Savings Plans and EC2 Instance Savings Plans are generated independently, based on the same historical On-Demand usage in the selected lookback period. 

To use the tools in the AWS Cost Management console to recommend potential savings and model the different discount pricing:
1. Log in to the AWS Cost Management console.
2. Navigate to Savings Plans on the left-hand side.
3. Click on Recommendations.  Here you can view recommendations for both Compute Savings Plans and EC2 Instance Savings Plans.
<img src={require('./assets/figure1.png').default}/>
4. There are several options that will help further customize recommendations:

	a. Recommendation level
	- Payer - Recommendations at the Organizations master account level are calculated considering usage across all accounts that have Savings Plans discount sharing enabled. This is to recommend a commitment that maximizes savings across your accounts.
	- Linked account - Recommendations are calculated at the individual or member account level to maximize savings for each account.

	b. Savings Plans term
	- 1 year 
	- 3 years

	c. Payment option
	- All upfront
	- Partial upfront
	- No upfront

	d. Calculate recommendations based on the past 7, 30, or 60 days.

5. You can modify the different parameters to see how the recommendations change – try changing the term from 1 year to 3 years or changing the payment option from All Upfront to No Upfront.
6. The overall dollar amount per month and percentage saved compared to On-Demand pricing will be displayed in the Recommendation details panel.

## Purchasing Savings Plans
To purchase the recommended Savings Plans, you first add the recommendation to your cart and then submit your order:
1. Once you're satisfied with the recommendations and have chosen the Savings Plans that work best for your requirements, click the “Add Savings Plan to Cart” button at the bottom of the page.
<img src={require('./assets/figure2.png').default}/>
2. After adding the Savings Plans to your cart, click “Cart” on the left-hand navigation menu to review your order.
3. Click the Submit order button to place your order.
<img src={require('./assets/figure3.png').default}/>
 
