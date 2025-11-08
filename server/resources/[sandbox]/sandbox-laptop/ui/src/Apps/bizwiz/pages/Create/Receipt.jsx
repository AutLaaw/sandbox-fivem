import React, { useState, useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import {
	Grid,
	TextField,
	ButtonGroup,
	Button,
	Backdrop,
	FormControlLabel,
	Checkbox,
	MenuItem,
} from '@mui/material';
import { makeStyles } from '@mui/styles';
import _ from 'lodash';
import moment from 'moment';

import Nui from '../../../../util/Nui';
import { Loader, Editor, Modal } from '../../../../components';
import { useAlert } from '../../../../hooks';
import BusinessSearch from '../../components/BusinessSearch';

const useStyles = makeStyles((theme) => ({
	wrapper: {
		padding: '20px 10px 20px 20px',
		height: '95%',
	},
	editorField: {
		marginBottom: 10,
	},
	title: {
		fontSize: 22,
		color: theme.palette.text.main,
		textAlign: 'center',
	},
	col: {
		height: '100%',
		padding: 5,
	},
	formActions: {
		paddingBottom: 10,
		marginBottom: 5,
		borderBottom: `1px inset ${theme.palette.border.divider}`,
	},
	positiveButton: {
		borderColor: `${theme.palette.success.main}80`,
		color: theme.palette.success.main,
		'&:hover': {
			borderColor: theme.palette.success.main,
			background: `${theme.palette.success.main}14`,
		},
	},
}));

const recTypes = [
	{
		value: 'General',
		jobs: false,
	},
	{
		value: 'Regular Repair',
		jobs: ['redline', 'hayes', 'autoexotics', 'ottos', 'bennys', 'paleto_tuners', 'dreamworks'],
	},
	{
		value: 'Full Repair',
		jobs: ['redline', 'hayes', 'autoexotics', 'ottos', 'bennys', 'paleto_tuners', 'dreamworks'],
	},
	{
		value: 'Lockpick',
		jobs: ['redline', 'hayes', 'autoexotics', 'ottos', 'bennys', 'paleto_tuners', 'dreamworks'],
	},
	{
		value: 'Performance Upgrades',
		jobs: ['redline', 'hayes', 'autoexotics', 'ottos', 'bennys', 'paleto_tuners', 'dreamworks'],
	},
	{
		value: 'Discounted Repair',
		jobs: ['redline', 'hayes', 'autoexotics', 'ottos', 'bennys', 'paleto_tuners', 'dreamworks'],
	},
	{
		value: 'Repair Kits',
		jobs: ['redline', 'hayes', 'autoexotics', 'ottos', 'bennys', 'paleto_tuners', 'dreamworks'],
	},
];

export default ({ onNav, data }) => {
	const classes = useStyles();
	const dispatch = useDispatch();
	const alert = useAlert();
	const onDuty = useSelector((state) => state.data.data.onDuty);

	const initialState = {
		notes: '',
		type: recTypes.filter((r) => !r.jobs || r.jobs.includes(onDuty))[0]
			?.value,
		customerName: '',
		customerNumber: '',
		paymentAmount: '',
		paymentPaid: '',
		workers: Array(),
		workersInput: '',
	};

	const [loading, setLoading] = useState(false);
	const [state, setState] = useState(initialState);
	const [workers, setWorkers] = useState(Array());

	useEffect(() => {
		const f = async (id) => {
			setLoading(true);
			try {
				let res = await (
					await Nui.send('BusinessReceiptView', {
						id,
					})
				).json();
				if (res) {
					setState(res);
				}
			} catch (err) {
				console.log(err);
				alert('Unable to Load Receipt');
			}
			setLoading(false);
		};

		if (data?.id) f(data.id);
	}, []);

	const onSubmit = async (e) => {
		e.preventDefault();

		if (state.customerName == '') {
			alert('Must Add Customer Name');
		} else {
			try {
				if (Boolean(state?._id)) {
					let res = await (
						await Nui.send('BusinessReceiptUpdate', {
							id: state._id,
							Report: {
								type: state.type,
								customerName: state.customerName,
								customerNumber: state.customerNumber,
								paymentAmount: state.paymentAmount,
								paymentPaid: state.paymentPaid,
								workers: state.workers,
								notes: state.notes,
								time: state.time,
								author: state.author,
							},
						})
					).json();

					if (res) onNav('View/Receipt', { id: state._id });
					else alert('Unable to Update');
				} else {
					let res = await (
						await Nui.send('BusinessReceiptCreate', {
							doc: {
								type: state.type,
								customerName: state.customerName,
								customerNumber: state.customerNumber,
								paymentAmount: state.paymentAmount,
								paymentPaid: state.paymentPaid,
								workers: state.workers,
								notes: state.notes,
								time: Date.now(),
							},
						})
					).json();

					if (res) {
						onNav('View/Receipt', { id: res._id });
					} else alert('Unable to Create');
				}
			} catch (err) {
				console.log(err);
				alert('Unable to Create');
			}
		}
	};

	return (
		<div className={classes.wrapper}>
			<Backdrop open={loading} style={{ zIndex: 100 }}>
				<Loader text="Loading" />
			</Backdrop>
			<Grid
				container
				style={{ height: '100%', paddingBottom: 10 }}
				spacing={2}
			>
				<Grid item xs={12}>
					<Grid container className={classes.formActions}>
						<Grid item xs={10}>
							<div className={classes.title}>
								{Boolean(state?._id)
									? `Edit Receipt`
									: `New Receipt`}
							</div>
						</Grid>
						<Grid item xs={2} style={{ textAlign: 'right' }}>
							<ButtonGroup fullWidth color="inherit">
								<Button
									className={classes.positiveButton}
									onClick={onSubmit}
								>
									{`${Boolean(state?._id) ? 'Edit' : 'Create'
										} Receipt`}
								</Button>
							</ButtonGroup>
						</Grid>
					</Grid>
				</Grid>
				<Grid item xs={6} className={classes.col}>
					<TextField
						select
						fullWidth
						label="Receipt Type"
						disabled={Boolean(state?._id)}
						name="type"
						className={classes.editorField}
						value={state.type}
						onChange={(e) =>
							setState({ ...state, type: e.target.value })
						}
					>
						{recTypes
							.filter((r) => !r.jobs || r.jobs.includes(onDuty))
							.map((option) => (
								<MenuItem
									key={option.value}
									value={option.value}
								>
									{option.value}
								</MenuItem>
							))}
					</TextField>
					<TextField
						className={classes.editorField}
						label="Customer Name"
						fullWidth
						placeholder="Customer Name"
						value={state.customerName}
						onChange={(e) =>
							setState({ ...state, customerName: e.target.value })
						}
					/>
					<TextField
						className={classes.editorField}
						label="Customer Phone Number"
						fullWidth
						placeholder="Customer Phone Number"
						value={state.customerNumber}
						onChange={(e) =>
							setState({
								...state,
								customerNumber: e.target.value,
							})
						}
					/>
					<TextField
						className={classes.editorField}
						label="Payment Charged"
						fullWidth
						placeholder="Payment Charged"
						value={state.paymentAmount}
						onChange={(e) =>
							setState({
								...state,
								paymentAmount: e.target.value,
							})
						}
					/>
					<TextField
						className={classes.editorField}
						label="Payment Paid"
						fullWidth
						placeholder="Payment Paid"
						value={state.paymentPaid}
						onChange={(e) =>
							setState({ ...state, paymentPaid: e.target.value })
						}
					/>
				</Grid>
				<Grid item xs={6} className={classes.col}>
					<BusinessSearch
						disableSelf
						label={`Additional Employees`}
						placeholder="Bob, Tim, Dave"
						value={state.workers}
						inputValue={state.workersInput}
						options={workers}
						setOptions={setWorkers}
						job={onDuty ?? 'none'}
						onChange={(e, nv) => {
							if (nv.length == 0) {
								setState({
									...state,
									workers: [],
									workersInput: '',
								});
							} else {
								setState({
									...state,
									workers: nv,
									workersInput: '',
								});
							}
						}}
						onInputChange={(e, nv) =>
							setState({ ...state, workersInput: nv })
						}
					/>
					{!loading && (
						<Editor
							allowMedia
							name="notes"
							title="Additional Notes"
							placeholder={'Enter Content'}
							disabled={loading}
							value={state.notes}
							onChange={(e) => {
								setState({ ...state, notes: e.target.value });
							}}
						/>
					)}
				</Grid>
			</Grid>
		</div>
	);
};
