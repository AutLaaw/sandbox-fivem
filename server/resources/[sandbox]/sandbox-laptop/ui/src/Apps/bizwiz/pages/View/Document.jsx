import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { Divider, List, ListItem, ListItemText, Grid, Alert, Button, ButtonGroup } from '@mui/material';
import { makeStyles } from '@mui/styles';
import Moment from 'react-moment';

import { Loader, UserContent } from '../../../../components';
import Nui from '../../../../util/Nui';
import { useJobPermissions, useAlert } from '../../../../hooks';
const useStyles = makeStyles((theme) => ({
	wrapper: {
		padding: '20px 10px 20px 20px',
		height: '100%',
	},
	notes: {
		color: theme.palette.text.alt,
		padding: '8px 16px',
		whiteSpace: 'pre-line',
		'& img': {
			width: '100%',
			maxWidth: 300,
		},
	},
	link: {
		color: theme.palette.text.alt,
		transition: 'color ease-in 0.15s',
		'&:hover': {
			color: theme.palette.primary.main,
		},
	},
	officerLink: {
		color: theme.palette.text.alt,
		transition: 'color ease-in 0.15s',
		'&:hover': {
			color: theme.palette.primary.main,
		},
		'&:not(:last-of-type)': {
			content: '", "',
			color: theme.palette.text.main,
		},
	},
	maxHeight: {
		maxHeight: "60vh",
		overflowY: 'scroll',
	},
}));

export default ({ data, onNav }) => {
	const classes = useStyles();
    const dispatch = useDispatch();
	const alert = useAlert();
	const hasJobPerm = useJobPermissions();
    const onDuty = useSelector((state) => state.data.data.onDuty);

	const [err, setErr] = useState(false);
	const [loading, setLoading] = useState(false);
	const [report, setReport] = useState(null);

	const onEdit = () => {
        onNav('Create/Document', { id: report._id });
	};

	const onDelete = async () => {
		if (hasJobPerm('TABLET_DELETE_DOCUMENT', onDuty)) {
			try {
				let res = await (
					await Nui.send('BusinessDocumentDelete', {
						id: report._id,
					})
				).json();
				if (res) {
                    alert('Document Deleted');

                    onNav('Dashboard')
				} else alert('Unable to Delete Document');
			} catch (err) {
				console.log(err);
                alert('Unable to Delete Document');
			}
		}
	};

	const canEditReport = () => {
		return hasJobPerm('TABLET_PIN_DOCUMENT', onDuty);
	};

	const fetch = async () => {
		if (!data?.id) return;
		// setReport({
		//   _id: 0,
		//   title: 'This is a report title',
		//   notes: '<p><a title=\"sedfsdf\" href=\"https://google.com\">https://google.com</a></p>',
		//   author: {},
		//   lastUpdated: {
		//     SID: 3,
		//     Callsign: 302,
		//     First: 'John',
		//     Last: 'Police',
		//     Time: 1628967582 * 1000,
		//   }
		// });
		// return

		setLoading(true);
		try {
			let res = await (
				await Nui.send('BusinessDocumentView', {
					id: data?.id,
				})
			).json();

			if (res) setReport(res);
			else alert('Unable to Load Document');
		} catch (err) {
			console.log(err);
            alert('Unable to Load Document');
			setErr(true);
		}
		setLoading(false);
	};

	useEffect(() => {
		fetch();
	}, []);

	return (
		<div>
			{loading || (!report && !err) ? (
				<div className={classes.wrapper} style={{ position: 'relative' }}>
					<Loader static text="Loading" />
				</div>
			) : err ? (
				<Grid className={classes.wrapper} container>
					<Grid item xs={12}>
						<Alert variant="outlined" severity="error">
							Invalid Document ID
						</Alert>
					</Grid>
				</Grid>
			) : (
				<>
					<Grid className={classes.wrapper} container spacing={2}>
						<Grid item xs={12}>
							<ButtonGroup fullWidth>
								<Button onClick={fetch} disabled={loading}>
									Refresh
								</Button>
								<Button disabled={!canEditReport} onClick={onEdit}>
									Edit Document
								</Button>
								{hasJobPerm('TABLET_DELETE_DOCUMENT', onDuty) && <Button onClick={onDelete}>Delete Document</Button>}
							</ButtonGroup>
						</Grid>
						<Grid item xs={12}>
							<Grid container spacing={2}>
								<Grid item xs={6}>
									<ListItem>
										<ListItemText primary="Document Title" secondary={report.title} />
									</ListItem>
								</Grid>
								<Grid item xs={3}>
									<ListItemText
										primary={
											<span>
												Created <Moment date={report.time} fromNow />
											</span>
										}
										secondary={
											<span>
												By&nbsp;
												{`${report.author.First} ${report.author.Last} (${report.author.SID})`}
												&nbsp;on&nbsp;
												<Moment date={report.time} format="LLL" />
											</span>
										}
									/>
								</Grid>
								<Grid item xs={3}>
									{report.lastUpdated && (
										<ListItemText
											primary={
												<span>
													Last Updated <Moment date={report.lastUpdated?.Time} fromNow />
												</span>
											}
											secondary={
												<span>
													By&nbsp;
													{`${report.lastUpdated.First} ${report.lastUpdated.Last} (${report.lastUpdated.SID})`}
													&nbsp;on&nbsp;
													<Moment date={report.lastUpdated?.Time} format="LLL" />
												</span>
											}
										/>
									)}
								</Grid>
							</Grid>
							<Divider flexItem />
						</Grid>
						<Grid item xs={12} className={classes.maxHeight}>
							<List>
								<ListItem>
									<ListItemText primary="Document" />
								</ListItem>
								<div className={classes.notes}>
									<UserContent wrapperClass={classes.notes} content={report.notes} />
								</div>
							</List>
						</Grid>
					</Grid>
				</>
			)}
		</div>
	);
};
