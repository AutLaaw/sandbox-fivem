/* eslint-disable react/prop-types */
import React, { useState } from 'react';
import { useDispatch } from 'react-redux';
import { TextField, FormControl, MenuItem, Autocomplete } from '@mui/material';
import { makeStyles } from '@mui/styles';
import { LocalizationProvider, DatePicker } from '@mui/x-date-pickers';
import { getCodeList } from 'country-list';
import { AdapterMoment } from '@mui/x-date-pickers/AdapterMoment';
import moment from 'moment';

import Nui from '../../util/Nui';

import { STATE_CHARACTERS } from '../../util/States';
import { CreateCharacter } from '../../util/NuiEvents';

const useStyles = makeStyles((theme) => ({
	wrapper: {
		width: 650,
		height: 'fit-content',
		maxHeight: '85vh',
		position: 'absolute',
		top: 0,
		bottom: 0,
		right: 0,
		left: 0,
		margin: 'auto',
		background: `linear-gradient(135deg, ${theme.palette.secondary.dark}98 0%, ${theme.palette.secondary.dark}95 100%)`,
		borderRadius: 12,
		border: `1px solid ${theme.palette.primary.main}40`,
		boxShadow: `0 12px 48px rgba(0, 0, 0, 0.7), 0 0 0 1px ${theme.palette.primary.main}20`,
		overflow: 'hidden',
		display: 'flex',
		flexDirection: 'column',
	},
	createForm: {
		padding: '24px 32px 20px',
		overflowY: 'auto',
		'&::-webkit-scrollbar': {
			width: 6,
		},
		'&::-webkit-scrollbar-thumb': {
			background: `${theme.palette.primary.main}60`,
			borderRadius: 3,
		},
		'&::-webkit-scrollbar-track': {
			background: 'rgba(0, 0, 0, 0.2)',
		},
	},
	title: {
		fontSize: 24,
		fontWeight: 700,
		paddingBottom: 16,
		marginBottom: 18,
		color: theme.palette.text.main,
		textShadow: '0 2px 4px rgba(0, 0, 0, 0.5)',
		borderBottom: `1px solid ${theme.palette.border.divider}30`,
	},
	button: {
		fontSize: 14,
		fontWeight: 700,
		padding: '10px 24px',
		borderRadius: 8,
		userSelect: 'none',
		minWidth: 100,
		textAlign: 'center',
		cursor: 'pointer',
		transition: 'all 0.3s ease',
		textTransform: 'uppercase',
		letterSpacing: '0.8px',
		'&:disabled': {
			opacity: 0.4,
			cursor: 'not-allowed',
		},
		'&:hover:not(:disabled)': {
			transform: 'translateY(-1px)',
		},
	},
	positive: {
		background: `linear-gradient(135deg, ${theme.palette.success.main} 0%, ${theme.palette.success.dark} 100%)`,
		border: `1px solid ${theme.palette.success.light}40`,
		color: theme.palette.text.dark,
		'&:hover:not(:disabled)': {
			boxShadow: `0 4px 16px ${theme.palette.success.main}50`,
		},
	},
	negative: {
		background: 'rgba(255, 255, 255, 0.08)',
		border: `1px solid ${theme.palette.border.divider}40`,
		color: theme.palette.text.main,
		'&:hover:not(:disabled)': {
			background: 'rgba(255, 255, 255, 0.12)',
			transform: 'translateY(-1px)',
			boxShadow: '0 4px 12px rgba(0, 0, 0, 0.3)',
		},
	},
	actionData: {
		padding: '18px 32px 22px',
		display: 'flex',
		justifyContent: 'flex-end',
		gap: 12,
	},
	form: {
		display: 'flex',
		flexWrap: 'wrap',
		gap: 16,
	},
	formControl: {
		width: 'calc(50% - 9px)',
		display: 'block',
	},
	formControlFull: {
		width: '100%',
		display: 'block',
	},
	formControl2: {
		width: '100%',
		display: 'block',
	},
	input: {
		width: '100%',
	},
}));

const genders = [
	{
		value: 0,
		label: 'Male',
	},
	{
		value: 1,
		label: 'Female',
	},
];

const countriesOrigin = getCodeList();
const date = new Date();
date.setFullYear(date.getFullYear() - 18);
const date2 = new Date();
date2.setFullYear(date2.getFullYear() - 100);

export default () => {
	const classes = useStyles();
	const dispatch = useDispatch();

	const countries = Object.keys(countriesOrigin).map((k) => {
		let c = countriesOrigin[k];
		return {
			label: c,
			value: k,
		};
	});

	const [state, setState] = useState({
		first: '',
		last: '',
		dob: moment().subtract(18, 'years'),
		gender: 0,
		bio: '',
		origin: null,
		originInput: '',
	});

	const onChange = (evt) => {
		if (evt.target.name == 'first' || evt.target.name == 'last') {
			setState({
				...state,
				[evt.target.name]: evt.target.value.replace(/\s/g, ''),
			});
		} else {
			setState({
				...state,
				[evt.target.name]: evt.target.value,
			});
		}
	};

	const onSubmit = (evt) => {
		evt.preventDefault();

		const data = {
			first: state.first,
			last: state.last,
			gender: state.gender,
			dob: state.dob,
			lastPlayed: -1,
			origin: state.origin,
		};

		Nui.send(CreateCharacter, data);
		dispatch({
			type: 'LOADING_SHOW',
			payload: { message: 'Creating Character' },
		});
	};

	return (
		<LocalizationProvider dateAdapter={AdapterMoment}>
			<div className={classes.wrapper}>
				<div className={classes.createForm}>
					<div className={classes.title}>Create Character</div>
					<form
						autoComplete="off"
						id="createForm"
						className={classes.form}
						onSubmit={onSubmit}
					>
						<FormControl className={classes.formControl}>
							<TextField
								className={classes.input}
								required
								label="First Name"
								name="first"
								variant="outlined"
								value={state.first}
								onChange={onChange}
							/>
						</FormControl>
						<FormControl className={classes.formControl}>
							<TextField
								className={classes.input}
								required
								label="Last Name"
								name="last"
								variant="outlined"
								value={state.last}
								onChange={onChange}
							/>
						</FormControl>
						<FormControl className={classes.formControlFull}>
							<Autocomplete
								value={state.origin}
								onChange={(e, v) => {
									onChange({
										target: {
											name: 'origin',
											value: v,
										},
									});
								}}
								inputValue={state.originInput}
								onInputChange={(e, v) => {
									onChange({
										target: {
											name: 'originInput',
											value: v,
										},
									});
								}}
								options={countries}
								getOptionLabel={(option) =>
									Boolean(option) ? option.label : ''
								}
								renderInput={(params) => (
									<TextField
										{...params}
										label="Country of Origin"
										variant="outlined"
									/>
								)}
							/>
						</FormControl>
						<FormControl className={classes.formControl}>
							<TextField
								className={classes.input}
								required
								select
								label="Gender"
								name="gender"
								value={state.gender}
								onChange={onChange}
								variant="outlined"
							>
								{genders.map((option) => (
									<MenuItem
										key={option.value}
										value={option.value}
									>
										{option.label}
									</MenuItem>
								))}
							</TextField>
						</FormControl>
						<FormControl className={classes.formControl}>
							<DatePicker
								className={classes.input}
								openTo="year"
								autoOk
								animateYearScrolling
								disableFuture
								required
								label="Date of Birth"
								views={['year', 'month', 'day']}
								value={state.dob}
								onChange={(newDate) =>
									onChange({
										target: { name: 'dob', value: newDate },
									})
								}
								renderInput={(params) => (
									<TextField fullWidth {...params} />
								)}
								slotProps={{
									textField: {
										helperText: 'MM/DD/YYYY',
									},
								}}
							/>
						</FormControl>
						{/* <FormControl className={classes.formControl2}>
							<TextField
								className={classes.input}
								required
								label="Character Biography"
								name="bio"
								multiline
								rows="3"
								value={state.bio}
								onChange={onChange}
								variant="outlined"
							/>
						</FormControl> */}
					</form>
				</div>
				<div className={classes.actionData}>
					<button
						type="button"
						className={`${classes.button} ${classes.negative}`}
						onClick={() => {
							dispatch({
								type: 'SET_STATE',
								payload: { state: STATE_CHARACTERS },
							});
						}}
					>
						Cancel
					</button>
					<button
						type="submit"
						className={`${classes.button} ${classes.positive}`}
						form="createForm"
					>
						Create
					</button>
				</div>
			</div>
		</LocalizationProvider>
	);
};
