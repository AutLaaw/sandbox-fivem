/* eslint-disable react/prop-types */
import React, { useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import Moment from 'react-moment';
import {
	Fade,
	Dialog,
	DialogActions,
	DialogContent,
	DialogContentText,
	DialogTitle,
	Button,
} from '@mui/material';
import { makeStyles } from '@mui/styles';

import Nui from '../../../util/Nui';
import { SelectCharacter, DeleteCharacter } from '../../../util/NuiEvents';

const useStyles = makeStyles((theme) => ({
	container: {
		width: 310,
		height: 100,
		padding: 0,
		display: 'inline-flex',
		background: `linear-gradient(135deg, ${theme.palette.secondary.dark}98 0%, ${theme.palette.secondary.dark}92 100%)`,
		borderRadius: 8,
		border: `1px solid ${theme.palette.secondary.light}30`,
		transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
		userSelect: "none",
		boxShadow: '0 3px 10px rgba(0, 0, 0, 0.4), inset 0 1px 0 rgba(255, 255, 255, 0.05)',
		overflow: 'hidden',
		position: 'relative',
		'&::before': {
			content: '""',
			position: 'absolute',
			left: 0,
			top: 0,
			bottom: 0,
			width: 3,
			background: `linear-gradient(180deg, ${theme.palette.secondary.light}60 0%, ${theme.palette.secondary.light}20 100%)`,
			transition: 'all 0.3s ease',
		},
		'&.active': {
			borderColor: `${theme.palette.primary.main}60`,
			boxShadow: `0 4px 16px ${theme.palette.primary.main}40, 0 0 0 1px ${theme.palette.primary.main}30, inset 0 1px 0 rgba(255, 255, 255, 0.08)`,
			'&::before': {
				background: `linear-gradient(180deg, ${theme.palette.primary.main} 0%, ${theme.palette.primary.main}80 100%)`,
				boxShadow: `0 0 10px ${theme.palette.primary.main}60`,
			},
		},
		'&:hover': {
			transform: 'translateY(-2px)',
			borderColor: `${theme.palette.primary.dark}50`,
			boxShadow: '0 6px 20px rgba(0, 0, 0, 0.5), inset 0 1px 0 rgba(255, 255, 255, 0.08)',
			cursor: 'pointer',
			'&::before': {
				background: `linear-gradient(180deg, ${theme.palette.primary.dark} 0%, ${theme.palette.primary.dark}70 100%)`,
				width: 4,
			},
		},
	},
	stateId: {
		width: 60,
		display: 'flex',
		alignItems: 'center',
		justifyContent: 'center',
		fontSize: 24,
		fontWeight: 700,
		textAlign: 'center',
		background: 'rgba(0, 0, 0, 0.2)',
		borderRight: `1px solid ${theme.palette.border.divider}40`,
		color: theme.palette.primary.main,
		textShadow: '0 2px 8px rgba(0, 0, 0, 0.5)',
	},
	details: {
		padding: '8px 10px',
		flex: 1,
		display: 'flex',
		flexDirection: 'column',
		justifyContent: 'space-evenly',
	},
	detail: {
		overflow: 'hidden',
		textOverflow: 'ellipsis',
		whiteSpace: 'nowrap',
		'&.name': {
			fontSize: 19,
			fontWeight: 700,
			color: theme.palette.text.main,
			textShadow: '0 2px 6px rgba(0, 0, 0, 0.5)',
			letterSpacing: '0.5px',
			lineHeight: 1.2,
		},
		'&.job': {
			fontSize: 12.5,
			opacity: 0.8,
			color: theme.palette.text.alt,
			display: 'flex',
			alignItems: 'center',
			fontWeight: 500,
		},
		'&.played': {
			fontSize: 11.5,
			opacity: 0.65,
			color: theme.palette.text.alt,
			fontWeight: 400,
			'& small': {
				fontSize: 11,
				opacity: 0.95,
				fontWeight: 500,
			},
		},
	},
 	deleteDialog: {
		'& .MuiDialog-paper': {
			background: `linear-gradient(135deg, ${theme.palette.secondary.dark}98 0%, ${theme.palette.secondary.dark}95 100%)`,
			borderRadius: 12,
			border: `1px solid ${theme.palette.error.main}40`,
			boxShadow: `0 12px 48px rgba(0, 0, 0, 0.7), 0 0 0 1px ${theme.palette.error.main}20`,
			minWidth: 480,
		},
		'& .MuiDialogTitle-root': {
			fontSize: 24,
			fontWeight: 700,
			color: theme.palette.text.main,
			textShadow: '0 2px 4px rgba(0, 0, 0, 0.5)',
			padding: '24px 28px 16px',
			borderBottom: `1px solid ${theme.palette.border.divider}30`,
		},
		'& .MuiDialogContent-root': {
			padding: '24px 28px',
		},
		'& .MuiDialogContentText-root': {
			color: theme.palette.text.alt,
			fontSize: 15,
			lineHeight: 1.6,
		},
		'& .MuiDialogActions-root': {
			padding: '16px 28px 24px',
			gap: 12,
		},
		'& .MuiButton-root': {
			borderRadius: 8,
			padding: '10px 24px',
			fontSize: 14,
			fontWeight: 700,
			textTransform: 'uppercase',
			letterSpacing: '0.8px',
			transition: 'all 0.3s ease',
			minWidth: 100,
		},
		'& .MuiButton-colorInherit': {
			background: 'rgba(255, 255, 255, 0.08)',
			border: `1px solid ${theme.palette.border.divider}40`,
			'&:hover': {
				background: 'rgba(255, 255, 255, 0.12)',
				transform: 'translateY(-1px)',
				boxShadow: '0 4px 12px rgba(0, 0, 0, 0.3)',
			},
		},
		'& .MuiButton-colorPrimary': {
			background: `linear-gradient(135deg, ${theme.palette.error.main} 0%, ${theme.palette.error.dark} 100%)`,
			border: `1px solid ${theme.palette.error.light}40`,
			color: theme.palette.text.main,
			'&:hover': {
				boxShadow: `0 4px 16px ${theme.palette.error.main}50`,
				transform: 'translateY(-1px)',
			},
		},
	},
}));

export default ({ character }) => {
	const classes = useStyles();
	const dispatch = useDispatch();
	const selected = useSelector((state) => state.characters.selected);

	const [open, setOpen] = useState(false);

	const onClick = () => {
		dispatch({
			type: 'LOADING_SHOW',
			payload: { message: 'Getting Spawn Points' },
		});
		dispatch({
			type: 'SELECT_CHARACTER',
			payload: {
				character: character,
			},
		});
		Nui.send(SelectCharacter, { id: character.ID });
	};

	const onRightClick = (e) => {
		e.preventDefault();
		setOpen(true);
	};

	const onDelete = () => {
		dispatch({
			type: 'LOADING_SHOW',
			payload: { message: 'Deleting Character' },
		});
		Nui.send(DeleteCharacter, { id: character.ID });
	};

	return (
		<Fade in={true}>
			<div
				className={`${classes.container} ${
					selected?.ID == character?.ID ? 'active' : ''
				}`}
				onDoubleClick={onClick}
				onContextMenu={onRightClick}
			>
				<div className={classes.stateId}>{character.SID}</div>
				<div className={classes.details}>
					<div className={`${classes.detail} name`}>
						{character.First} {character.Last}
					</div>
					<div className={`${classes.detail} job`}>
						{!Boolean(character?.Jobs) ||
						character?.Jobs?.length == 0 ? (
							<span>Unemployed</span>
						) : character?.Jobs?.length == 1 ? (
							<span>
								{character?.Jobs[0].Workplace
									? `${character?.Jobs[0].Workplace.Name} - ${character?.Jobs[0].Grade.Name}`
									: `${character?.Jobs[0].Name} - ${character?.Jobs[0].Grade.Name}`}
							</span>
						) : (
							<span>{character?.Jobs?.length} Jobs</span>
						)}
					</div>
					<div className={`${classes.detail} played`}>
						Last Played:{' '}
						{+character.LastPlayed === -1 ? (
							<span className={classes.highlight}>Never</span>
						) : (
							<span className={classes.highlight}>
								<small>
									<Moment
										date={+character.LastPlayed}
										format="M/D/YYYY h:mm:ss A"
										withTitle
									/>
								</small>
							</span>
						)}
					</div>
				</div>
				<Dialog 
					open={open} 
					onClose={() => setOpen(false)}
					className={classes.deleteDialog}
				>
					<DialogTitle>Delete Character</DialogTitle>
					<DialogContent>
						<DialogContentText>
							Are you sure you want to permanently delete{' '}
							<strong style={{ color: '#fff' }}>
								{character.First} {character.Last}
							</strong>
							?
							<br /><br />
							This action is <strong>completely irreversible</strong> and cannot be undone by anyone, including staff members.
						</DialogContentText>
					</DialogContent>
					<DialogActions>
						<Button onClick={() => setOpen(false)} color="inherit">
							Cancel
						</Button>
						<Button onClick={onDelete} color="primary" autoFocus>
							Delete
						</Button>
					</DialogActions>
				</Dialog>
			</div>
		</Fade>
	);
};
