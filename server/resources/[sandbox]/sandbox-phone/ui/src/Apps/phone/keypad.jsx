import React, { useEffect, useState } from 'react';
import { useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import { Input, Grid, Button, IconButton, Avatar } from '@mui/material';
import { makeStyles } from '@mui/styles';
import InputMask from 'react-input-mask';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

import { useAlert } from '../../hooks';
import Nui from '../../util/Nui';

const useStyles = makeStyles((theme) => ({
	keypad: {
		height: '100%',
		display: 'flex',
		flexDirection: 'column',
		padding: 16,
		background: theme.palette.secondary.main,
	},
	infoContainer: {
		width: 'fit-content',
		margin: 'auto',
		margin: 'auto',
		position: 'relative',
		height: '25%',
		width: '100%',
	},
	inner: {
		width: '100%',
		position: 'absolute',
		height: 'fit-content',
		top: 0,
		bottom: 0,
		left: 0,
		right: 0,
		margin: 'auto',
	},
	callData: {
		textAlign: 'center',
		fontSize: 18,
		fontWeight: 'bold',
		maxWidth: '85%',
		overflow: 'hidden',
		textOverflow: 'ellipsis',
		whiteSpace: 'nowrap',
		margin: 'auto',
	},
	input: {
		maxWidth: '85%',
		width: '100%',
		margin: 'auto',
		display: 'flex',
	},
	keys: {
		flexGrow: 1,
	},
	keypadBtn: {
		textAlign: 'center',
		height: 75,
		fontSize: '24px',
		width: '100%',

		'&.nav': {
			color: theme.palette.text.main,

			'&:hover': {
				backgroundColor: `${theme.palette.text.alt}14`,
			},
		},

		'&.call:not(.disabled)': {
			color: theme.palette.success.light,

			'&:hover': {
				backgroundColor: `${theme.palette.success.dark}80`,
			},
		},
	},
}));

export default (props) => {
	const showAlert = useAlert();
	const classes = useStyles();
	const history = useNavigate();
	const limited = useSelector((state) => state.phone.limited);
	const contacts = useSelector((state) => state.data.data.contacts);
	const player = useSelector((state) => state.data.data.player);
	const callData = useSelector((state) => state.call.call);

	const [isAnon, setIsAnon] = useState(false);
	const [dialNumber, setDialNumber] = useState('');
	const [isContact, setIsContact] = useState(null);

	useEffect(() => {
		if (dialNumber != '' && !limited)
			setIsContact(
				contacts.filter((c) =>
					c.number.startsWith(dialNumber.replace(/\_/g, '')),
				)[0],
			);
		else setIsContact(null);
	}, [dialNumber]);

	const onChange = (e) => {
		setDialNumber(e.target.value);
	};

	const onBackClick = (e) => {
		setDialNumber(dialNumber.substring(0, dialNumber.length - 1));
	};

	const startcall = async (e) => {
		if (dialNumber.length == 12)
			if (dialNumber !== player.Phone) {
				if (callData == null) {
					try {
						let res = await (
							await Nui.send('CreateCall', {
								number: dialNumber,
								limited,
								isAnon,
							})
						).json();

						if (res) {
							history(`/apps/phone/call/${dialNumber}`);
						} else showAlert('Unable To Start Call');
					} catch (err) {
						console.error(err);
						showAlert('Unable To Start Call');
					}
				}
			} else {
				showAlert('Cannot Call Yourself, Idiot');
			}
	};

	const btnClick = (value) => {
		// TODO : Make this code cleaner
		let tmp = dialNumber.replace(/\-/g, '').replace(/\_/g, '') + value;
		if (tmp.length <= 10) {
			if (tmp.length > 3 && tmp.length < 7)
				setDialNumber(tmp.replace(/(\d{3})(\d{1,3})/, '$1-$2'));
			else
				setDialNumber(
					tmp.replace(/(\d{3})(\d{3})(\d{1,4})/, '$1-$2-$3'),
				);
		}
	};

	return (
		<div className={classes.keypad}>
			<div className={classes.infoContainer}>
				<div className={classes.inner}>
					{Boolean(isContact) ? (
						<div className={classes.callData}>{isContact.name}</div>
					) : (
						<div className={classes.callData}>Unknown Number</div>
					)}
					<div className={classes.input}>
						<InputMask
							mask="999-999-9999"
							value={dialNumber}
							onChange={onChange}
						>
							{() => (
								<Input
									className={classes.numInput}
									name="number"
									type="text"
									disableUnderline
									placeholder="___-___-____"
									inputProps={{
										style: { fontSize: 40 },
									}}
								/>
							)}
						</InputMask>
						<IconButton
							onClick={onBackClick}
							style={{ padding: 20 }}
						>
							<FontAwesomeIcon icon={['fas', 'delete-left']} />
						</IconButton>
					</div>
				</div>
			</div>
			<Grid container spacing={1} className={classes.keys}>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(1)}
					>
						1
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(2)}
					>
						2
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(3)}
					>
						3
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(4)}
					>
						4
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(5)}
					>
						5
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(6)}
					>
						6
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(7)}
					>
						7
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(8)}
					>
						8
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(9)}
					>
						9
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						disabled
					>
						*
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(0)}
					>
						0
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						disabled
						color="primary"
						className={classes.keypadBtn}
					>
						#
					</Button>
				</Grid>
				<Grid item xs={4}>
					{!limited && (
						<Button
							color="primary"
							className={`${classes.keypadBtn} nav`}
							onClick={() => history('/apps/phone/recent')}
						>
							<FontAwesomeIcon
								icon={['fas', 'clock-rotate-left']}
								style={{ fontSize: 18 }}
							/>
						</Button>
					)}
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={`${classes.keypadBtn} call ${
							dialNumber.replace(/\_/g, '').length < 12 ||
							Boolean(callData)
								? 'disabled'
								: ''
						}`}
						disabled={
							dialNumber.replace(/\_/g, '').length < 12 ||
							Boolean(callData)
						}
						onClick={startcall}
					>
						<FontAwesomeIcon
							icon={['fas', 'phone']}
							style={{ fontSize: 36 }}
						/>
					</Button>
				</Grid>
				<Grid item xs={4}>
					{!limited && (
						<Button
							color="primary"
							className={`${classes.keypadBtn} nav`}
							onClick={() => history('/apps/contacts')}
						>
							<FontAwesomeIcon
								icon={['fas', 'address-book']}
								style={{ fontSize: 18 }}
							/>
						</Button>
					)}
				</Grid>
			</Grid>
		</div>
	);

	return (
		<div className={classes.wrapper}>
			<div className={classes.number}>
				{!limited && (
					<IconButton
						className={classes.recent}
						onClick={() => history('/apps/phone/recent')}
					>
						<FontAwesomeIcon icon={['fas', 'clock-rotate-left']} />
					</IconButton>
				)}
				<Grid container spacing={1}>
					<Grid item xs={12} className={classes.callinfo}>
						{isAnon ? 'Anonymous' : 'Standard'}
					</Grid>
					<Grid item xs={12} className={classes.callinfo}>
						<div className={classes.name}>
							{isContact.length > 0
								? isContact.length > 1
									? 'Matches Multiple Contacts'
									: isContact[0].name
								: 'Unknown'}
						</div>
					</Grid>
					<Grid item xs={1} className={classes.anonSymbol}>
						{isAnon ? <div>#</div> : null}
					</Grid>
					<Grid item xs={8}>
						<InputMask
							mask="999-999-9999"
							value={dialNumber}
							onChange={onChange}
						>
							{() => (
								<Input
									className={classes.numInput}
									name="number"
									type="text"
									disableUnderline
									placeholder="___-___-____"
									inputProps={{
										style: { fontSize: 40 },
									}}
								/>
							)}
						</InputMask>
					</Grid>
					<Grid item xs={3} className={classes.backBtn}>
						<IconButton
							onClick={onBackClick}
							style={{ padding: 20 }}
						>
							<FontAwesomeIcon icon={['fas', 'delete-left']} />
						</IconButton>
					</Grid>
				</Grid>
			</div>
			<Grid container spacing={1}>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(1)}
					>
						1
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(2)}
					>
						2
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(3)}
					>
						3
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(4)}
					>
						4
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(5)}
					>
						5
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(6)}
					>
						6
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(7)}
					>
						7
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(8)}
					>
						8
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(9)}
					>
						9
					</Button>
				</Grid>
				<Grid item xs={4}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						disabled
					>
						*
					</Button>
				</Grid>
				<Grid item xs={4} className={classes.keypadBtn}>
					<Button
						color="primary"
						className={classes.keypadBtn}
						onClick={() => btnClick(0)}
					>
						0
					</Button>
				</Grid>
				<Grid item xs={4} className={classes.keypadBtn}>
					<Button
						disabled
						color="primary"
						className={classes.keypadBtn}
					>
						#
					</Button>
				</Grid>
				<Grid item xs={12} className={classes.keypadBtn}>
					<IconButton
						className={
							dialNumber.replace(/\_/g, '').length == 12 &&
							callData == null
								? classes.keypadAction
								: classes.keypadActionDis
						}
						onClick={startcall}
					>
						<FontAwesomeIcon
							icon={['fas', 'phone']}
							style={{ fontSize: 40 }}
						/>
					</IconButton>
				</Grid>
			</Grid>
		</div>
	);
};
