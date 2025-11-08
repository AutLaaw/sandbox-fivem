_loanConfig = {
	defaultInterestRate = 15,
	missedPayments = {
		limit = 4, -- The default value for the amount of payments that can be missed in a row
		interestIncrease = 2.5,
		charge = 5, -- As Percent of original loan amount
	},
	loanDefaulting = {
		charge = 15, -- As Percent of original loan amount
	},
	paymentInterval = (60 * 60 * 24 * 7), -- 7 days
}

_creditScoreConfig = {
	default = 150,
	max = 1400,
	min = 100,
	removal = {
		missedLoanPayment = 15,
		defaultedLoan = 35,
	},
	addition = {
		loanPaymentMin = 60, -- This is divided by number of weeks/payments and gets 15 more per 50k
		loanPaymentMax = 140,
		completingLoan = 20,
		completingLoanNoMissed = 30,
	},
	allowedLoanMultipliers = { -- The loan multiplier for levels of credit score
		["vehicle"] = {
			{ value = 0, multiplier = 0 },
			{ value = 100, multiplier = 200 },
			{ value = 250, multiplier = 250 },
			{ value = 350, multiplier = 280 },
			{ value = 450, multiplier = 320 },
			{ value = 600, multiplier = 400 },
			{ value = 800, multiplier = 600 },
			{ value = 900, multiplier = 800 },
			{ value = 1000, multiplier = 1000 },
			{ value = 1100, multiplier = 1200 },
			{ value = 1200, multiplier = 1400 },
		},
		["property"] = {
			{ value = 0, multiplier = 0 },
			{ value = 170, multiplier = 300 },
			{ value = 220, multiplier = 550 },
			{ value = 350, multiplier = 800 },
			{ value = 500, multiplier = 1000 },
			{ value = 800, multiplier = 1200 },
			{ value = 1000, multiplier = 1300 },
			{ value = 1200, multiplier = 1400 },
		},
	},
}
