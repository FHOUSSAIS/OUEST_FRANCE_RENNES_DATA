SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
/*=============================================
-- Description:	Simulation de la démcauleuse
-- Déroulement de la simulation
-- Vérification Skate en place
-- Vérification Bobine déposée depuis 15s ET pas de Bobine en déballage
-- => Déplacement de la bobine en Déballage
-- Vérification Bobine en déballage depuis 15s ET pas de Bobine en Sortie TRR
-- => Déplacement de la bobine en sortie TRR
-- =============================================*/
CREATE PROCEDURE [dbo].[SPC_DMC_SIMULATION]
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Simulation'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

DECLARE @simulation_demaculeuse INT = (SELECT CONVERT(INT, PAR_VAL) FROM dbo.PARAMETRE WHERE dbo.PARAMETRE.PAR_NOM = 'SPC_SIMU_DEMAC')
DECLARE @simulation_agv INT = (SELECT CONVERT(INT, PAR_VAL) FROM dbo.PARAMETRE WHERE dbo.PARAMETRE.PAR_NOM = 'SPC_SIMU_AGV')

DECLARE @idCharge INT
DECLARE @idLigne INT
DECLARE @v_emetteurInterne INT = -6
DECLARE @v_emetteurExterne INT = -6

DECLARE @idVariableActiveMessage INT
DECLARE @idVariableBobine1 INT
DECLARE @idVariableBobine2 INT
DECLARE @idVariableNewBobine INT
DECLARE @idVariableType INT
DECLARE @valeurVariableActiveMessage INT
DECLARE @valeurVariableBobine1 INT
DECLARE @valeurVariableBobine2 INT
DECLARE @valeurVariableNewBobine INT
DECLARE @valeurVariableType INT

DECLARE @idDemande VARCHAR(20)
DECLARE @laize INT
DECLARE @diametre INT
DECLARE @grammage NUMERIC(5,2)
DECLARE @fournisseur INT
DECLARE @idDemandeEmettrice VARCHAR(20)
DECLARE @idSysteme BIGINT
DECLARE @idBase BIGINT
DECLARE @idSousBase BIGINT


	IF(@simulation_demaculeuse = 1)
	BEGIN
		-- Bobine en Entrée Démaculeuse
		IF EXISTS (	SELECT
						1
					FROM dbo.SPC_DEMACULEUSE
					JOIN dbo.INT_CHARGE_VIVANTE
						ON dbo.INT_CHARGE_VIVANTE.CHG_IDSYSTEME = dbo.SPC_DEMACULEUSE.SDL_IDSYSTEME_ENTREE
						AND dbo.INT_CHARGE_VIVANTE.CHG_IDBASE = dbo.SPC_DEMACULEUSE.SDL_IDBASE_ENTREE
						AND dbo.INT_CHARGE_VIVANTE.CHG_IDSOUSBASE = dbo.SPC_DEMACULEUSE.SDL_IDSOUSBASE_ENTREE
					JOIN dbo.INT_ADRESSE ADRESSE_DEPOSE
						ON ADRESSE_DEPOSE.ADR_IDSYSTEME = dbo.SPC_DEMACULEUSE.SDL_IDSYSTEME_ENTREE
						AND ADRESSE_DEPOSE.ADR_IDBASE = dbo.SPC_DEMACULEUSE.SDL_IDBASE_ENTREE
						AND ADRESSE_DEPOSE.ADR_IDSOUSBASE = dbo.SPC_DEMACULEUSE.SDL_IDSOUSBASE_ENTREE
						AND DATEDIFF(SECOND, dbo.INT_CHARGE_VIVANTE.CHG_DATEOPERATION, GETDATE()) > 15
						AND EXISTS (SELECT
										1
									FROM dbo.INT_ADRESSE ADRESSE_DEBALLAGE
									WHERE ADRESSE_DEBALLAGE.ADR_IDTYPEMAGASIN = 2
									AND ADRESSE_DEBALLAGE.ADR_MAGASIN = 3
									AND ADRESSE_DEBALLAGE.ADR_COTE = 2
									AND ADRESSE_DEBALLAGE.ADR_COULOIR = ADRESSE_DEPOSE.ADR_COULOIR
									and ADRESSE_DEBALLAGE.ADR_IDETAT_OCCUPATION = 1))
		BEGIN
			-- Récupération de la charge et de la ligne
			SELECT
				@idCharge = dbo.INT_CHARGE_VIVANTE.CHG_IDCHARGE,
				@idLigne = dbo.SPC_DEMACULEUSE.SDL_IDLIGNE
			FROM dbo.SPC_DEMACULEUSE
			JOIN dbo.INT_CHARGE_VIVANTE
				ON dbo.INT_CHARGE_VIVANTE.CHG_IDSYSTEME = dbo.SPC_DEMACULEUSE.SDL_IDSYSTEME_ENTREE
				AND dbo.INT_CHARGE_VIVANTE.CHG_IDBASE = dbo.SPC_DEMACULEUSE.SDL_IDBASE_ENTREE
				AND dbo.INT_CHARGE_VIVANTE.CHG_IDSOUSBASE = dbo.SPC_DEMACULEUSE.SDL_IDSOUSBASE_ENTREE
			JOIN dbo.INT_ADRESSE ADRESSE_DEPOSE
				ON ADRESSE_DEPOSE.ADR_IDSYSTEME = dbo.SPC_DEMACULEUSE.SDL_IDSYSTEME_ENTREE
				AND ADRESSE_DEPOSE.ADR_IDBASE = dbo.SPC_DEMACULEUSE.SDL_IDBASE_ENTREE
				AND ADRESSE_DEPOSE.ADR_IDSOUSBASE = dbo.SPC_DEMACULEUSE.SDL_IDSOUSBASE_ENTREE
			WHERE DATEDIFF(SECOND, dbo.INT_CHARGE_VIVANTE.CHG_DATEOPERATION, GETDATE()) > 15
			AND EXISTS (SELECT
							1
						FROM dbo.INT_ADRESSE ADRESSE_DEBALLAGE
						WHERE ADRESSE_DEBALLAGE.ADR_IDTYPEMAGASIN = 2
						AND ADRESSE_DEBALLAGE.ADR_MAGASIN = 3
						AND ADRESSE_DEBALLAGE.ADR_COULOIR = ADRESSE_DEPOSE.ADR_COULOIR
						AND ADRESSE_DEBALLAGE.ADR_COTE = 2
						AND ADRESSE_DEBALLAGE.ADR_IDETAT_OCCUPATION = 1)

			-- Mise à jour variable automate
			SET @valeurVariableActiveMessage = 1
			EXEC @retour = dbo.SPC_DMC_GET_IDBOBINE @v_idBobine = @idCharge, @v_idBobineToChar1 = @valeurVariableBobine1 OUT, @v_idBobineToChar2 = @valeurVariableBobine2 OUT
			SET @valeurVariableNewBobine = 0
	
			SELECT
				@idVariableActiveMessage = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_ACTIVEMESSAGE,
				@idVariableBobine1 = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE1,
				@idVariableBobine2 = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE2,
				@idVariableNewBobine = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_NEWBOBINE
			FROM dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE
			WHERE dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_ACTION = 31
			AND dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDLIGNE = @idLigne

			UPDATE dbo.VARIABLE_AUTOMATE SET VAU_VALEUR = @valeurVariableBobine1 WHERE dbo.VARIABLE_AUTOMATE.VAU_ID = @idVariableBobine1;
			UPDATE dbo.VARIABLE_AUTOMATE SET VAU_VALEUR = @valeurVariableBobine2 WHERE dbo.VARIABLE_AUTOMATE.VAU_ID = @idVariableBobine2
			UPDATE dbo.VARIABLE_AUTOMATE SET VAU_VALEUR = @valeurVariableNewBobine WHERE dbo.VARIABLE_AUTOMATE.VAU_ID = @idVariableNewBobine
			UPDATE dbo.VARIABLE_AUTOMATE set VAU_VALEUR = @valeurVariableActiveMessage WHERE dbo.VARIABLE_AUTOMATE.VAU_ID = @idVariableActiveMessage

			-- Simulation de la réception de l'information automate
			EXEC @retour = dbo.SPC_DMC_EVT_LECTUREVARIABLE	@v_emetteurInterne = @v_emetteurInterne,
															@v_emetteurExterne = @v_emetteurExterne,
															@v_idVariableAutomate = @idVariableActiveMessage,
															@v_valeur = @valeurVariableActiveMessage

		END
		-- Bobine en station de démaculage
		-- Bobine en Entrée Démaculeuse
		IF EXISTS (	SELECT
						1
					FROM dbo.INT_CHARGE_VIVANTE
					JOIN dbo.INT_ADRESSE ADRESSE_DEBALLAGE
						ON ADRESSE_DEBALLAGE.ADR_IDSYSTEME = dbo.INT_CHARGE_VIVANTE.CHG_IDSYSTEME
						AND ADRESSE_DEBALLAGE.ADR_IDBASE = dbo.INT_CHARGE_VIVANTE.CHG_IDBASE
						AND ADRESSE_DEBALLAGE.ADR_IDSOUSBASE = dbo.INT_CHARGE_VIVANTE.CHG_IDSOUSBASE
					WHERE DATEDIFF(SECOND, dbo.INT_CHARGE_VIVANTE.CHG_DATEOPERATION, GETDATE()) > 15
					AND ADRESSE_DEBALLAGE.ADR_IDTYPEMAGASIN = 2 
					AND ADRESSE_DEBALLAGE.ADR_MAGASIN = 3 
					AND ADRESSE_DEBALLAGE.ADR_COTE = 2
					AND EXISTS (SELECT
									1
								FROM dbo.INT_ADRESSE ADRESSE_SORTIE_TRR
								WHERE ADRESSE_SORTIE_TRR.ADR_IDTYPEMAGASIN = 2
								AND ADRESSE_SORTIE_TRR.ADR_MAGASIN = 3
								AND ADRESSE_SORTIE_TRR.ADR_COTE = 3
								AND ADRESSE_SORTIE_TRR.ADR_COULOIR = ADRESSE_DEBALLAGE.ADR_COULOIR
								and ADRESSE_SORTIE_TRR.ADR_IDETAT_OCCUPATION = 1))
		BEGIN
			SET @idCharge = NULL
			SET @idLigne = NULL
			SELECT
				@idCharge = dbo.INT_CHARGE_VIVANTE.CHG_IDCHARGE,
				@idLigne = ADRESSE_DEBALLAGE.ADR_COULOIR
			FROM dbo.INT_CHARGE_VIVANTE
			JOIN dbo.INT_ADRESSE ADRESSE_DEBALLAGE
				ON ADRESSE_DEBALLAGE.ADR_IDSYSTEME = dbo.INT_CHARGE_VIVANTE.CHG_IDSYSTEME
				AND ADRESSE_DEBALLAGE.ADR_IDBASE = dbo.INT_CHARGE_VIVANTE.CHG_IDBASE
				AND ADRESSE_DEBALLAGE.ADR_IDSOUSBASE = dbo.INT_CHARGE_VIVANTE.CHG_IDSOUSBASE
			WHERE DATEDIFF(SECOND, dbo.INT_CHARGE_VIVANTE.CHG_DATEOPERATION, GETDATE()) > 15
			AND ADRESSE_DEBALLAGE.ADR_IDTYPEMAGASIN = 2 
			AND ADRESSE_DEBALLAGE.ADR_MAGASIN = 3 
			AND ADRESSE_DEBALLAGE.ADR_COTE = 2
			AND EXISTS (SELECT
							1
						FROM dbo.INT_ADRESSE ADRESSE_SORTIE_TRR
						WHERE ADRESSE_SORTIE_TRR.ADR_IDTYPEMAGASIN = 2
						AND ADRESSE_SORTIE_TRR.ADR_MAGASIN = 3
						AND ADRESSE_SORTIE_TRR.ADR_COTE = 3
						AND ADRESSE_SORTIE_TRR.ADR_COULOIR = ADRESSE_DEBALLAGE.ADR_COULOIR
						and ADRESSE_SORTIE_TRR.ADR_IDETAT_OCCUPATION = 1)

			-- Valeur des Variables Automate
			SET @valeurVariableActiveMessage = 1
			EXEC @retour = dbo.SPC_DMC_GET_IDBOBINE @v_idBobine = @idCharge, @v_idBobineToChar1 = @valeurVariableBobine1 OUT, @v_idBobineToChar2 = @valeurVariableBobine2 OUT
			SET @valeurVariableType = 1

			-- Identifiant des variables Automate
			SELECT
				@idVariableActiveMessage = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_ACTIVEMESSAGE,
				@idVariableBobine1 = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE1,
				@idVariableBobine2 = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDBOBINE2,
				@idVariableType = dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_TYPE
			FROM dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE
			WHERE dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_ACTION = 51
			AND dbo.SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE.SLV_IDLIGNE = @idLigne

			-- Affectation des valeurs automate
			UPDATE dbo.VARIABLE_AUTOMATE SET VAU_VALEUR = @valeurVariableBobine1 WHERE dbo.VARIABLE_AUTOMATE.VAU_ID = @idVariableBobine1
			UPDATE dbo.VARIABLE_AUTOMATE SET VAU_VALEUR = @valeurVariableBobine2 WHERE dbo.VARIABLE_AUTOMATE.VAU_ID = @idVariableBobine2
			UPDATE dbo.VARIABLE_AUTOMATE SET VAU_VALEUR = @valeurVariableType WHERE dbo.VARIABLE_AUTOMATE.VAU_ID = @idVariableType
			UPDATE dbo.VARIABLE_AUTOMATE set VAU_VALEUR = @valeurVariableActiveMessage WHERE dbo.VARIABLE_AUTOMATE.VAU_ID = @idVariableActiveMessage

			EXEC @retour = dbo.SPC_DMC_EVT_LECTUREVARIABLE @v_emetteurInterne = @v_emetteurInterne, @v_emetteurExterne = @v_emetteurExterne, @v_idVariableAutomate = @idVariableActiveMessage, @v_valeur = @valeurVariableActiveMessage

		END
		
		-- Simulation AGV
		IF(@simulation_agv = 1)
		BEGIN
			SELECT TOP 1
				@idDemande = dbo.SPC_DMD_APPRO_DEMAC.SDD_IDDEMANDE,
				@idLigne = dbo.SPC_DMD_APPRO_DEMAC.SDD_ROTATIVE,
				@laize = dbo.SPC_DMD_APPRO_DEMAC.SDD_LAIZE,
				@diametre = dbo.SPC_DMD_APPRO_DEMAC.SDD_DIAMETRE,
				@grammage = dbo.SPC_DMD_APPRO_DEMAC.SDD_GRAMMAGE,
				@fournisseur = dbo.SPC_DMD_APPRO_DEMAC.SDD_IDFOURNISSEUR,
				@idDemandeEmettrice = dbo.SPC_DMD_APPRO_DEMAC.SDD_IDDEMANDE_EMETTRICE,
				@idSysteme = dbo.SPC_DEMACULEUSE.SDL_IDSYSTEME_ENTREE,
				@idBase = dbo.SPC_DEMACULEUSE.SDL_IDBASE_ENTREE,
				@idSousBase = dbo.SPC_DEMACULEUSE.SDL_IDSOUSBASE_ENTREE
			FROM dbo.SPC_DMD_APPRO_DEMAC
			JOIN dbo.SPC_DEMACULEUSE ON dbo.SPC_DEMACULEUSE.SDL_IDLIGNE = dbo.SPC_DMD_APPRO_DEMAC.SDD_ROTATIVE
			WHERE dbo.SPC_DMD_APPRO_DEMAC.SDD_ETAT = 0
			ORDER BY dbo.SPC_DMD_APPRO_DEMAC.SDD_PRIORITE DESC, dbo.SPC_DMD_APPRO_DEMAC.SDD_DATE

			IF @idDemande IS NOT NULL 
			AND EXISTS(	SELECT
							1
						FROM dbo.SPC_DEMACULEUSE
						JOIN dbo.INT_ADRESSE
							ON dbo.INT_ADRESSE.ADR_IDSYSTEME = dbo.SPC_DEMACULEUSE.SDL_IDSYSTEME_ENTREE
							AND dbo.INT_ADRESSE.ADR_IDBASE = dbo.SPC_DEMACULEUSE.SDL_IDBASE_ENTREE
							AND dbo.INT_ADRESSE.ADR_IDSOUSBASE = dbo.SPC_DEMACULEUSE.SDL_IDSOUSBASE_ENTREE
						WHERE dbo.INT_ADRESSE.ADR_IDETAT_OCCUPATION = 1
						AND dbo.SPC_DEMACULEUSE.SDL_IDLIGNE = @idLigne)
			BEGIN
				EXEC @retour = dbo.SPC_SIMU_CREERBOBINE	@v_idCharge = @idCharge OUT,
														@v_chg_poids = 900,
														@v_chg_laize = @laize,
														@v_chg_diametre = @diametre,
														@v_chg_sensEnroulement = 1,
														@v_chg_grammage = @grammage,
														@v_chg_idFournisseur = @fournisseur,
														@v_idSysteme = @idSysteme,
														@v_idBase = @idBase,
														@v_idSousBase = @idSousBase
				IF(@retour = @CODE_OK)
				BEGIN
					UPDATE dbo.SPC_DMD_APPRO_DEMAC
					SET	SDD_IDBOBINE = @idCharge,
						SDD_ETAT = 3
					WHERE dbo.SPC_DMD_APPRO_DEMAC.SDD_IDDEMANDE = @idDemande
				END
			END
			
		END
	END
	RETURN @retour

END




