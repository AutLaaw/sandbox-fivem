import React, { useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { makeStyles } from '@mui/styles';
import { Button, Grid, FormControl, InputLabel, Select, OutlinedInput, ListItemSecondaryAction, MenuItem, ListItemText, TextField, List, ListItem, IconButton } from '@mui/material';

import { Loader, Modal } from '../../components';
import Nui from '../../util/Nui';
import Reputation from './component/Reputation';
import MyContract from './component/MyContract';
import { usePermissions, useAlert } from '../../hooks';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import NumberFormat from 'react-number-format';
import moment from 'moment';

const useStyles = makeStyles((theme) => ({
	wrapper: {
		position: 'relative',
		height: '100%',
		background: theme.palette.secondary.main,
		overflow: 'auto',
	},
	body: {
		padding: 10,
		height: '100%',
	},
	contractGrid: {
		overflow: 'auto',
		height: '100%',
	},
	emptyMsg: {
		width: '100%',
		textAlign: 'center',
		fontSize: 20,
		fontWeight: 'bold',
		marginTop: '22%',
	},
	editorField: {
		marginBottom: 15,
	},
	actionBtn: {
		fontSize: 14,
	},
}));

const vehicleClasses = [
	'D',
	'C',
	'B',
	'A',
	'A+',
	'S+',
];

export default ({ canBoost, banned, reputations }) => {
	const classes = useStyles();
	const hasPerm = usePermissions();
	const dispatch = useDispatch();
	const alert = useAlert();

	const myGroup = useSelector((state) => state.data.data.myGroup);
	const queue = useSelector((state) => state.data.data.boostingQueue);
	const alias = useSelector((state) => state.data.data.player.Profiles?.redline);

	const myContracts = useSelector((state) => state.data.data.player.BoostingContracts);

	// const [myContracts, setMyContracts] = useState(
	// 	[...Array(3).keys()].map((i) => {
	// 		return {
	// 			id: i,
	// 			owner: {
	// 				SID: 1,
	// 				Alias: 'MeFast',
	// 			},
	// 			vehicle: {
	// 				model: 'drafter',
	// 				label: 'Drafter',
	// 				class: 'A+',
	// 			},
	// 			prices: {
	// 				standard: {
	// 					price: 25,
	// 					coin: 'VRM',
	// 				},
	// 				scratch: {
	// 					price: 50,
	// 					coin: 'VRM',
	// 				},
	// 			},
	// 			expires: 1659553001,
	// 		};
	// 	}),
	// );

	const [queueModal, setQueueModal] = useState(false);

	const onQueueExit = async (e) => {
		e.preventDefault();

		try {
			const res = await (await Nui.send("Boosting:ExitQueue")).json();

			if (res) {
				alert('Left Queue');
			} else {
				alert('Failed to Leave Queue');
			}
		} catch (e) {
			console.log(e)
		}

		setQueueModal(false);
	};

	const onQueueEnter = async (e) => {
		e.preventDefault();

		if (alias && myGroup && (myGroup?.Members?.length >= 2 || hasPerm('lsunderground', 'admin'))) {
			try {
				const res = await (await Nui.send("Boosting:EnterQueue")).json();

				if (res?.success) {
					alert('Entered Queue');
				} else {
					if (res?.message) {
						alert(res.message);
					} else {
						alert('Failed to Enter Queue');
					}
				}
			} catch (e) {
				console.log(e)
			}
		} else {
			setQueueModal(true);
		}
	};

	const [adminSub, setAdminSub] = useState(false);
	const [creatingContract, setCreatingContract] = useState(null);

	const startCreatingContract = () => {
		setCreatingContract({
			vehicle: '',
			make: '',
			model: '',
			class: 'D',
			trackers: 0,
			price: 20,
			skipRep: false,
			payoutOverride: 0,
		})
	};

	const onContractValueChange = (e) => {
		setCreatingContract({
			...creatingContract,
			[e.target.name]: e.target.value
		})
	};

	const onCreateContract = async (e) => {
		e.preventDefault();

		try {
			const data = {
				...creatingContract,
				trackers: parseInt(creatingContract.trackers),
				price: parseInt(creatingContract.price),
				payoutOverride: parseInt(creatingContract.payoutOverride),
			}
			setCreatingContract(null);

			const res = await (await Nui.send("Boosting:Admin:CreateContract", data)).json();
			if (res) {
				alert('Contract Created Successfully');
			} else {
				alert('Failed to Create Contract');
			}
		} catch (e) {
			console.log(e);
			alert('Failed to Create Contract');
		}
	};

	const [banning, setBanning] = useState(null);
	const [banList, setBanList] = useState(Array());
	const [banLoading, setBanLoading] = useState(false);

	const onStartBanning = async () => {
		setBanLoading(true);
		setBanning({
			SID: '',
		});

		try {
			const res = await (await Nui.send("Boosting:Admin:GetBans")).json();

			if (res) {
				setBanList(res);
			} else throw res;
		} catch (e) {
			console.log(e);

			alert('Failed to Fetch Banlist');
			setBanList(Array());

			// setBanList([
			// 	{ LSUNDGBan: ["Boosting"], SID: 1, First: "Ducking", Last: "Here", RacingAlias: "monkaSteer" },
			// 	{ LSUNDGBan: ["Boosting"], SID: 1, First: "Ducking", Last: "Here", RacingAlias: "monkaSteer" },
			// ]);
		}
		setBanLoading(false);
	}

	const onBanValueChange = (e) => {
		setBanning({
			...creatingContract,
			[e.target.name]: e.target.value
		});
	};

	const onBan = async (e) => {
		e.preventDefault();

		setBanLoading(true);

		try {
			const res = await (await Nui.send("Boosting:Admin:Ban", { SID: parseInt(banning.SID) })).json();

			if (res) {
				alert('Ban Successful');
				onStartBanning();

			} else throw res;
		} catch (e) {
			console.log(e);
			alert('Failed to Ban');
		}

		setBanLoading(false);
	};

	const onUnban = async (stateId) => {
		setBanLoading(true);

		try {
			const res = await (await Nui.send("Boosting:Admin:Unban", { SID: stateId })).json();

			if (res) {
				alert('Unban Successful');
				onStartBanning();

			} else throw res;
		} catch (e) {
			console.log(e);
			alert('Failed to Unban');
		}

		setBanLoading(false);
	};

	if (banned) {
		return <div className={classes.wrapper}>
			<div className={classes.emptyMsg}>Denied...</div>
		</div>
	}

	if (!canBoost) {
		return <div className={classes.wrapper}>
			<div className={classes.emptyMsg}>Insufficient Reputation to Begin Boosting</div>
		</div>
	}

	if (!alias) {
		return <div className={classes.wrapper}>
			<div className={classes.emptyMsg}>A Racing Alias is Required to Use This</div>
		</div>
	}

	const boostRep = reputations?.find(r => r.id == "Boosting");

	return (
		<div className={classes.wrapper}>
			<Grid container style={{ height: '100%', overflow: 'hidden' }}>
				{hasPerm('lsunderground', 'admin') && (
					<Grid item xs={1} style={{ padding: 4 }}>
						{adminSub ? (
							<Grid container spacing={1} style={{ height: '100%' }}>
								<Grid item xs={12}>
									<Button
										fullWidth
										color="success"
										style={{ height: '100%' }}
										onClick={startCreatingContract}
									>
										<FontAwesomeIcon icon={['fas', 'file-plus']} />
									</Button>
								</Grid>
								<Grid item xs={12}>
									<Button
										fullWidth
										color="error"
										style={{ height: '100%' }}
										onClick={onStartBanning}
									>
										<FontAwesomeIcon icon={['fas', 'ban']} />
									</Button>
								</Grid>
							</Grid>
						) : (
							<Button
								fullWidth
								color="success"
								style={{ height: '100%' }}
								onClick={() => setAdminSub(true)}
							>
								<FontAwesomeIcon icon={['fas', 'user-shield']} />
							</Button>
						)}

					</Grid>
				)}
				<Grid item xs={hasPerm('lsunderground', 'admin') ? 10 : 11}>
					<Reputation
						rep={boostRep || {
							id: 'Boosting',
							label: 'Boosting',
							value: 0,
							current: {
								value: 0,
								label: 'D',
							},
							next: {
								value: 50000,
								label: 'C',
							},
						}}
					/>
				</Grid>
				<Grid item xs={1} style={{ padding: 4 }}>
					<Button
						fullWidth
						color={queue ? "error" : "success"}
						style={{ height: '100%' }}
						onClick={queue ? () => setQueueModal(true) : onQueueEnter}
						disabled={!myGroup || myGroup?.State === "boosting"}
					>
						{queue ? "Exit Queue" : "Enter Queue"}
					</Button>
				</Grid>
				<Grid
					item
					xs={12}
					style={{ padding: 10, height: 'calc(100% - 82px)' }}
				>
					<Grid
						container
						spacing={2}
						className={classes.contractGrid}
					>
						{myContracts && myContracts.filter(c => (c.expires * 1000) > Date.now()).length > 0 ? (
							myContracts.filter(c => (c.expires * 1000) > Date.now()).map((contract) => {
								return (
									<MyContract
										key={`contract-${contract.id}`}
										contract={contract}
										repLevel={boostRep?.value ?? 1}
									/>
								);
							})
						) : (
							<div className={classes.emptyMsg}>You Have No Available Contracts</div>
						)}
					</Grid>
				</Grid>
			</Grid>
			<Modal
				open={queueModal}
				title={queue ? "Exit Queue" : "Entry Requirements!"}
				closeLang={queue ? "Close" : "I Understand"}
				maxWidth="md"
				submitLang="Exit"
				onSubmit={queue ? onQueueExit : null}
				submitColor="error"
				onClose={() => setQueueModal(null)}
			>
				{queue ? (
					<p>You have been in the queue for {moment(queue?.joined * 1000).fromNow(true)}, are you sure you want to leave?</p>
				) : (
					<p>In order to join the queue, you must have a racing alias and you must be part of a group with at least 2 members.</p>
				)}
			</Modal>
			<Modal
				open={Boolean(creatingContract)}
				title={"Custom Contract Creation"}
				closeLang={"Cancel"}
				maxWidth="md"
				submitLang="Create"
				onSubmit={onCreateContract}
				onClose={() => setCreatingContract(null)}
			>
				{Boolean(creatingContract) && (
					<>
						<FormControl fullWidth className={classes.editorField}>
							<InputLabel id="class">
								Vehicle Class
							</InputLabel>
							<Select
								labelId="class"
								name="class"
								fullWidth
								value={creatingContract.class}
								onChange={onContractValueChange}
								input={
									<OutlinedInput
										fullWidth
										label="Vehicle Class"
									/>
								}
							>
								{vehicleClasses.map(c => {
									return (
										<MenuItem key={c} value={c}>
											<ListItemText primary={c} />
										</MenuItem>
									);
								})}
							</Select>
						</FormControl>
						<TextField
							fullWidth
							required
							label="Vehicle"
							name="vehicle"
							className={classes.editorField}
							value={creatingContract.vehicle}
							onChange={onContractValueChange}
							helperText="The model of the vehicle to spawn"
						/>
						<TextField
							fullWidth
							required
							label="Vehicle Make"
							name="make"
							className={classes.editorField}
							value={creatingContract.make}
							onChange={onContractValueChange}
							helperText="e.g Aston Martin"
						/>
						<TextField
							fullWidth
							required
							label="Vehicle Model"
							name="model"
							className={classes.editorField}
							value={creatingContract.model}
							onChange={onContractValueChange}
							helperText="e.g. DBS"
						/>
						<NumberFormat
							fullWidth
							required
							label="Number of Trackers"
							helperText="How many trackers will be on the vehicle (set to 0 to skip stage)"
							name="trackers"
							className={classes.editorField}
							value={creatingContract.trackers}
							onChange={onContractValueChange}
							type="tel"
							isNumericString
							customInput={TextField}
						/>
						<NumberFormat
							fullWidth
							required
							label="Price in $VRM"
							helperText="How much will the contract cost"
							name="price"
							className={classes.editorField}
							value={creatingContract.price}
							onChange={onContractValueChange}
							type="tel"
							isNumericString
							customInput={TextField}
						/>
						<FormControl fullWidth className={classes.editorField}>
							<InputLabel id="skipRep">
								Skip Reputation Reward
							</InputLabel>
							<Select
								labelId="skipRep"
								name="skipRep"
								fullWidth
								value={creatingContract.skipRep}
								onChange={onContractValueChange}
								input={
									<OutlinedInput
										fullWidth
										label="Skip Reputation Reward"
									/>
								}
							>
								<MenuItem key={"disabled"} value={false}>
									<ListItemText primary={"No"} />
								</MenuItem>
								<MenuItem key={"enabled"} value={true}>
									<ListItemText primary={"Yes"} />
								</MenuItem>
							</Select>
						</FormControl>
						<NumberFormat
							fullWidth
							required
							label="Payout Reward"
							helperText="How much will be paid out at the end of the contract. Leave at 0 for default."
							name="payoutOverride"
							className={classes.editorField}
							value={creatingContract.payoutOverride}
							onChange={onContractValueChange}
							type="tel"
							isNumericString
							customInput={TextField}
						/>
					</>
				)}
			</Modal>
			<Modal
				open={Boolean(banning)}
				title={"LSUNDG Banning System"}
				closeLang="Close"
				maxWidth="md"
				submitLang="Ban"
				submitColor="error"
				onSubmit={onBan}
				onClose={() => setBanning(null)}
			>
				{Boolean(banning) && !banLoading ? (
					<>
						<TextField
							fullWidth
							required
							label="Target State ID"
							name="SID"
							className={classes.editorField}
							value={banning.SID}
							onChange={onBanValueChange}
							helperText="State ID of who you want to ban"
						/>
						<h3>Ban List</h3>
						<List>
							{banList.map(b => {
								return (
									<ListItem divider key={b.SID}>
										<ListItemText
											primary={`${b.RacingAlias} - ${b.First} ${b.Last} (SID #${b.SID}) - Banned From: ${b.LSUNDGBan.join(', ')}`}
										/>
										<ListItemSecondaryAction>
											<IconButton
												edge="end"
												color="error"
												onClick={() => onUnban(b.SID)}
												className={classes.actionBtn}
											>
												<FontAwesomeIcon
													icon={[
														'fas',
														'user-plus',
													]}
												/>
											</IconButton>
										</ListItemSecondaryAction>
									</ListItem>
								)
							})}
						</List>

					</>
				) : (
					<Loader text="Loading" />
				)}
			</Modal>
		</div>
	);
};
