import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { Button, ButtonGroup } from '@mui/material';
import { makeStyles } from '@mui/styles';

import Nui from '../../util/Nui';
import { Motd } from '../../components';
import logo from '../../assets/imgs/logo_banner.png';

import SpawnButton from './components/SpawnButton';
import { STATE_CHARACTERS } from '../../util/States';
import { PlayCharacter } from '../../util/NuiEvents';

const useStyles = makeStyles((theme) => ({
	canvas: {
		height: '100vh',
		width: '100vw',
		position: 'relative',
	},
	logo: {
		width: 300,
		height: 169,
		position: 'absolute',
		right: 24,
		top: 24,
		filter: 'drop-shadow(0 4px 12px rgba(0, 0, 0, 0.5))',
		transition: 'transform 0.3s ease',
		'&:hover': {
			transform: 'scale(1.02)',
		},
	},
	spawnContainer: {
		position: 'absolute',
		top: 0,
		bottom: 0,
		left: 24,
		margin: 'auto',
		width: 310,
		height: 'fit-content',
		maxHeight: '80vh',
		overflow: 'auto',
		padding: '6px',
		background: 'rgba(0, 0, 0, 0.25)',
		borderRadius: 10,
		boxShadow: '0 6px 24px rgba(0, 0, 0, 0.5), inset 0 1px 0 rgba(255, 255, 255, 0.05)',
		'&::-webkit-scrollbar': {
			width: 6,
		},
		'&::-webkit-scrollbar-thumb': {
			background: `${theme.palette.primary.main}60`,
			borderRadius: 3,
		},
		'&::-webkit-scrollbar-track': {
			background: 'rgba(0, 0, 0, 0.2)',
			borderRadius: 3,
		},
	},
	spawnInfo: {
		height: 'fit-content',
		width: 420,
		position: 'absolute',
		right: 0,
		left: 0,
		bottom: 80,
		margin: 'auto',
		background: `linear-gradient(135deg, ${theme.palette.secondary.dark}98 0%, ${theme.palette.secondary.dark}95 100%)`,
		borderRadius: 12,
		border: `1px solid ${theme.palette.primary.main}40`,
		boxShadow: `0 12px 48px rgba(0, 0, 0, 0.7), 0 0 0 1px ${theme.palette.primary.main}20`,
		overflow: 'hidden',
		display: 'flex',
		flexDirection: 'column',
	},
	charInfo: {
		padding: '20px 28px',
		display: 'flex',
		alignItems: 'center',
		gap: 32,
	},
	infoRow: {
		display: 'flex',
		flexDirection: 'column',
		gap: 4,
		flex: 1,
	},
	button: {
		fontSize: 14,
		fontWeight: 700,
		padding: '12px 24px',
		textTransform: 'uppercase',
		letterSpacing: '0.8px',
		transition: 'all 0.3s ease',
		borderRadius: '0 !important',
		'&:hover': {
			transform: 'translateY(-1px)',
		},
	},
	cancelButton: {
		background: 'rgba(255, 255, 255, 0.08) !important',
		border: `1px solid rgba(255, 255, 255, 0.1) !important`,
		color: '#fff !important',
		'&:hover': {
			background: 'rgba(255, 255, 255, 0.12) !important',
			boxShadow: '0 4px 12px rgba(0, 0, 0, 0.3) !important',
		},
	},
	playButton: {
		background: `linear-gradient(135deg, #4caf50 0%, #388e3c 100%) !important`,
		border: `1px solid rgba(76, 175, 80, 0.4) !important`,
		'&:hover': {
			boxShadow: '0 4px 16px rgba(76, 175, 80, 0.5) !important',
		},
	},
	label: {
		fontSize: 11,
		color: theme.palette.text.alt,
		fontWeight: 600,
		textTransform: 'uppercase',
		letterSpacing: '1px',
		opacity: 0.7,
	},
	data: {
		fontSize: 17,
		color: theme.palette.text.main,
		fontWeight: 600,
		textShadow: '0 2px 6px rgba(0, 0, 0, 0.5)',
		'&.highlight': {
			color: theme.palette.primary.main,
			fontSize: 18,
			fontWeight: 700,
		},
	},
	buttons: {
		borderRadius: 0,
		'& .MuiButton-root': {
			borderRadius: 0,
		},
	},
	divider: {
		width: 1,
		height: 40,
		background: `${theme.palette.border.divider}30`,
	},
}));

export default (props) => {
	const classes = useStyles();
	const dispatch = useDispatch();

	const motd = useSelector((state) => state.characters.motd);
	const spawns = useSelector((state) => state.spawn.spawns);
	const selected = useSelector((state) => state.spawn.selected);
	const selectedChar = useSelector((state) => state.characters.selected);

	const onSpawn = () => {
		Nui.send(PlayCharacter, {
			spawn: selected,
			character: selectedChar,
		});
		dispatch({
			type: 'LOADING_SHOW',
			payload: { message: 'Spawning' },
		});
		dispatch({
			type: 'UPDATE_PLAYED',
		});
		dispatch({ type: 'DESELECT_CHARACTER' });
		dispatch({ type: 'DESELECT_SPAWN' });
	};

	const goBack = () => {
		dispatch({ type: 'DESELECT_CHARACTER' });
		dispatch({ type: 'DESELECT_SPAWN' });
		dispatch({
			type: 'SET_STATE',
			payload: { state: STATE_CHARACTERS },
		});
	};

	return (
		<div className={classes.canvas}>
			{Boolean(motd) && <Motd message={motd} />}
			<img className={classes.logo} src={logo} alt="Logo" />
			<div className={classes.spawnContainer}>
				{spawns.map((spawn, i) => {
					return (
						<SpawnButton key={i} spawn={spawn} onPlay={onSpawn} />
					);
				})}
			</div>
			<div className={classes.spawnInfo}>
				<div className={classes.charInfo}>
					<div className={classes.infoRow}>
						<div className={classes.label}>Character</div>
						<div className={`${classes.data} highlight`}>
							{selectedChar.First} {selectedChar.Last}
						</div>
					</div>
					<div className={classes.divider}></div>
					<div className={classes.infoRow}>
						<div className={classes.label}>Location</div>
						{Boolean(selected) ? (
							<div className={classes.data}>{selected.label}</div>
						) : (
							<div className={classes.data} style={{ opacity: 0.5 }}>
								Select Location
							</div>
						)}
					</div>
				</div>
				<ButtonGroup fullWidth className={classes.buttons}>
					<Button
						fullWidth
						variant="contained"
						onClick={goBack}
						className={`${classes.button} ${classes.cancelButton}`}
					>
						Cancel
					</Button>
					{Boolean(selected) && (
						<Button
							fullWidth
							variant="contained"
							onClick={onSpawn}
							className={`${classes.button} ${classes.playButton}`}
						>
							Play
						</Button>
					)}
				</ButtonGroup>
			</div>
		</div>
	);
};
