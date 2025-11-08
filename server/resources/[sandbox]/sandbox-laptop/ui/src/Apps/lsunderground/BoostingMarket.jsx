import React, { useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { makeStyles } from '@mui/styles';
import { Button, Grid, FormControl, InputLabel, Select, OutlinedInput, ListItemSecondaryAction, MenuItem, ListItemText, TextField, List, ListItem, IconButton, Paper } from '@mui/material';

import { Loader, Modal } from '../../components';
import Nui from '../../util/Nui';
import Reputation from './component/Reputation';
import MarketContract from './component/MarketContract';
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

	titleWrapper: {
		padding: 10,
		background: theme.palette.secondary.dark,
		'&:not(:last-of-type)': {
			marginBottom: 10,
		},
	},
	titleDetails: {
		position: 'absolute',
		width: '100%',
		height: 'fit-content',
		top: 0,
		bottom: 0,
		margin: 'auto',
	},
	titleTitle: {
		fontSize: 20,
		color: theme.palette.primary.main,
		fontWeight: 'bold',
        textAlign: 'center',
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

export default ({ banned, reputations }) => {
	const classes = useStyles();
	const hasPerm = usePermissions();
	const dispatch = useDispatch();
	const alert = useAlert();

	const myGroup = useSelector((state) => state.data.data.myGroup);
	const queue = useSelector((state) => state.data.data.boostingQueue);
	const alias = useSelector((state) => state.data.data.player.Profiles?.redline);

	//const myContracts = useSelector((state) => state.data.data.player.BoostingContracts);

	const [myContracts, setMyContracts] = useState(
		[...Array(3).keys()].map((i) => {
			return {
				id: i,
				owner: {
					SID: 1,
					Alias: 'MeFast',
				},
				vehicle: {
					model: 'drafter',
					label: 'Drafter',
					class: 'A+',
				},
				prices: {
					standard: {
						price: 25,
						coin: 'VRM',
					},
					scratch: {
						price: 50,
						coin: 'VRM',
					},
				},
				expires: 1659553001,
			};
		}),
	);

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
		} catch(e) {
			console.log(e)
		}

		setQueueModal(false);
	};

	const onQueueEnter = async (e) => {
		e.preventDefault();

		// TODO: Set to 2 members
		if (alias && myGroup && (myGroup?.Members?.length >= 2 || hasPerm('lsunderground', 'admin'))) {
			try {
				const res = await (await Nui.send("Boosting:EnterQueue")).json();
	
				if (res) {
					alert('Entered Queue');
				} else {
					alert('Failed to Enter Queue');
				}
			} catch(e) {
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
		} catch(e) {
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
		} catch(e) {
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
		} catch(e) {
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
		} catch(e) {
			console.log(e);
			alert('Failed to Unban');
		}

		setBanLoading(false);
	};

	if (banned) {
		return <div className={classes.wrapper}>
			<div className={classes.emptyMsg}>Banned...</div>
		</div>
	}

	const boostRep = reputations?.find(r => r.id == "Boosting");

	return (
		<div className={classes.wrapper}>
			<Grid container style={{ height: '100%', overflow: 'hidden' }}>
				<Grid item xs={12}>
					<Paper className={classes.titleWrapper}>
						<Grid container>
							<Grid item xs={12} style={{ position: 'relative', height: 38 }}>
								<div className={classes.titleDetails}>
									<div className={classes.titleTitle}>Boosting Market</div>
								</div>
							</Grid>
						</Grid>
					</Paper>
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
						{myContracts && myContracts.length > 0 ? (
							myContracts.map((contract) => {
								return (
									<MarketContract
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
		</div>
	);
};
