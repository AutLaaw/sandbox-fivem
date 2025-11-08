import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { makeStyles } from '@mui/styles';
import {
	Grid,
	IconButton,
	List,
	ListItem,
	ListItemText,
	ListItemSecondaryAction,
} from '@mui/material';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { throttle } from 'lodash';
import Nui from '../../util/Nui';

import Window from '../../components/Window';
import { Loader } from '../../components';

const useStyles = makeStyles((theme) => ({
	wrapper: {
		height: '100%',
		background: theme.palette.secondary.main,
	},
	heading: {
		padding: 10,
		borderBottom: `1px solid ${theme.palette.border.divider}`,
	},
	actionBtn: {
		fontSize: 18,
		'&:not(:first-of-type)': {
			marginLeft: 15,
		},
	},
}));

export default (props) => {
	const classes = useStyles();
	const dispatch = useDispatch();

	const myData = useSelector((state) => state.data.data.player);
	const myGroup = useSelector((state) => state.data.data.myGroup);
	const isLeader = myGroup?.Members?.find(m => m.Leader)?.SID == myData.SID;

	const [loading, setLoading] = useState(false);
	const [requests, setRequests] = useState(Array());
	const [time, setTime] = useState(Date.now());

	const newNotifs = useSelector((state) => state.notifications.notifications);

	useEffect(() => {
		onRefresh();

		const interval = setInterval(() => setTime(Date.now()), 30000);
		return () => {
		  	clearInterval(interval);
		};
	}, []);

	useEffect(() => {
		if (newNotifs.filter(n => n?.data?.request).length > 0) {
			onRefresh();
		}
	}, [newNotifs]);
	
	const onRefresh = async () => {
		try {
			setLoading(true);
			let res = await (await Nui.send('GetTeamRequests')).json();
			setRequests(res);
		} catch (err) {
			console.log(err);
			
			setRequests([
				{
					id: 1,
					event: 'Laptop:Client:AcceptInvite',
					label: 'Group Invite',
					description: 'From Testy McTest',
					data: {
						SID: 2,
						Leader: 1,
					},
				},
				{
					id: 2,
					event: 'Laptop:Client:AcceptJob',
					label: 'Boosting Contract',
					description: 'Lamborghini Aventador (S+)',
					data: {
						Job: 'Boosting',
						Data: 'Checking',
					},
				},
			]);
		}
		
		setLoading(false);
	};
	
	const onAction = async (request, action) => {
		try {
			setLoading(true);
			let res = await (await Nui.send('TeamRequest', {
				...request,
				action,
			})).json();
		} catch (err) {
			console.log(err);
		}

		onRefresh();
	};

	const availableRequests = requests?.filter(r => r.expires > (Date.now() / 1000));

	return (
		<Grid item xs={4} style={{ padding: 10 }}>
			<Grid container>
				<Grid item xs={12}>
					<h3 className={classes.heading}>Incoming Requests</h3>
				</Grid>
				<Grid item xs={12}>
					<List>
						{!loading ? (
							Boolean(availableRequests) && availableRequests.length > 0 ? (
								availableRequests.map((request) => {
									return (
										<ListItem
											divider
											key={`request-${request.id}`}
										>
											<ListItemText
												primary={request.label}
												secondary={request.description}
											/>
											<ListItemSecondaryAction>
												{(isLeader || !request.team) && (
													<IconButton
														color="success"
														edge="end"
														onClick={() => onAction(request, "accept")}
														className={
															classes.actionBtn
														}
													>
														<FontAwesomeIcon
															icon={[
																'fas',
																'check',
															]}
														/>
													</IconButton>
												)}
												{(isLeader || !request.team) && (
													<IconButton
														color="error"
														edge="end"
														onClick={() => onAction(request, "deny")}
														className={
															classes.actionBtn
														}
													>
														<FontAwesomeIcon
															icon={['fas', 'x']}
														/>
													</IconButton>
												)}
											</ListItemSecondaryAction>
										</ListItem>
									);
								})
							) : (
								<ListItem>
									<ListItemText primary="No Pending Requests" />
								</ListItem>
							)
						) : (
							<Loader text="Loading" />
						)}
					</List>
				</Grid>
			</Grid>
		</Grid>
	);
};
