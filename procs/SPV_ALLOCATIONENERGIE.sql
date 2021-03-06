SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procedure		: SPV_ALLOCATIONENERGIE
-- Paramètre d'entrée	:
-- Paramètre de sortie	: @v_reveilAGV : Indique s'il faut réveiller les AGVs
-- Descriptif		: Cette procedure est appelée pour detruire tous les évenements
--			  energie terminés
--			  Recherche des evenements à traiter (En attente)
--			    1. Evenement de sortie de charge :
--			      -> Mise à jour de l'état de charge de l'AGV
--			      -> Evenement dans l'état Terminé
--			    2. Evenement d'envoi en charge
--			      -> Recherche d'un chargeur disponible
--			      => si OK
--			        - Creation d'une mission d'envoi en charge
--			        - Reservation objet Energie
--			        - Evenement dans l'état cours
--			    3. Evenement d'envoi en changement de batterie
--			      -> Recherche d'un chargeur
--			      => si OK
--			        - Creation d'une mission de changement de batterie
--			        - Reservation objet Energie
--			        - Evenement dans l'état cours
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_ALLOCATIONENERGIE]
	@v_reveilAGV bit output
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_status int,
	@v_retour int,
	@vc_idEvt int,
	@vc_idAgv tinyint,
	@vc_typeAct tinyint,
	@v_coe_id_1 smallint,
	@v_coe_id_2 smallint,
	@v_coe_type tinyint,
	@v_coe_rack tinyint,
	@v_idMission int,
	@v_tac_idsystemeexecution_1 bigint,
	@v_tac_idbaseexecution_1 bigint,
	@v_tac_idsousbaseexecution_1 bigint,
	@v_tac_affinage_1 tinyint,
	@v_tac_idsystemeexecution_2 bigint,
	@v_tac_idbaseexecution_2 bigint,
	@v_tac_idsousbaseexecution_2 bigint,
	@v_tac_affinage_2 tinyint,
	@v_ata_idaction int,
	@v_tac_idtache int,
	@v_par_valeur varchar(128)

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK int,
	@CODE_KO int

-- Déclaration des constantes d'états et de descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint

-- Déclaration des constantes d'état d'événement d'énergie
DECLARE
	@EVNT_ENATTENTE tinyint,
	@EVNT_ENCOURS tinyint,
	@EVNT_TERMINE tinyint

-- Déclaration des constantes de type d'objet énergie
DECLARE
	@TYPE_CHANGEMENT_BATTERIE_MANUEL int,
	@TYPE_RECHARGE_BATTERIE int,
	@TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_NAVETTE int,
	@TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME int

-- Déclaration des constantes de type d'événement d'énergie
DECLARE
	@TYPE_CHANGEMENT_BATTERIE int,
	@TYPE_ENTREE_CHARGE_PLAN int,
	@TYPE_SORTIE_CHARGE int,
	@TYPE_ENTREE_CHARGE_AUTO int

-- Déclaration des constantes d'action
DECLARE
	@ACTI_CHARGEMENT_BATTERIE_PLAN int,
	@ACTI_CHANGEMENT_BATTERIE_MANUEL int,
	@ACTI_CHANGEMENT_BATTERIE_AUTOMATIQUE int,
	@ACTI_DEPOSE_BATTERIE int,
	@ACTI_PRISE_BATTERIE int,
	@ACTI_CHARGEMENT_BATTERIE_AUTO int

-- Déclaration des constantes de type d'affinage
DECLARE
	@AFFI_AUCUN tinyint,
	@AFFI_ATTRIBUTION tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @EVNT_ENATTENTE = 1
	SET @EVNT_ENCOURS = 2
	SET @EVNT_TERMINE = 3
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @TYPE_CHANGEMENT_BATTERIE_MANUEL = 1
	SET @TYPE_RECHARGE_BATTERIE = 4
	SET @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_NAVETTE = 2
	SET @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME = 3
	SET @TYPE_CHANGEMENT_BATTERIE = 1
	SET @TYPE_ENTREE_CHARGE_PLAN = 2
	SET @TYPE_SORTIE_CHARGE = 3
	SET @TYPE_ENTREE_CHARGE_AUTO = 4
	SET @ACTI_CHARGEMENT_BATTERIE_PLAN = 32
	SET @ACTI_CHANGEMENT_BATTERIE_MANUEL = 64
	SET @ACTI_CHANGEMENT_BATTERIE_AUTOMATIQUE = 4096
	SET @ACTI_PRISE_BATTERIE = 16384
	SET @ACTI_DEPOSE_BATTERIE = 32768
	SET @ACTI_CHARGEMENT_BATTERIE_AUTO = 65536
	
	SET @AFFI_AUCUN = 0
	SET @AFFI_ATTRIBUTION = 1

-- Initialisation de la variable de retour
	SET @v_error = 0
	SET @v_status = @CODE_KO
	SET @v_retour = @CODE_KO

	set @v_reveilAGV = 0
	BEGIN TRAN
	declare c_newEvent CURSOR for select EEC_ID, EEC_AGV, EEC_TYPEACT
		from EVT_ENERGIE_EN_COURS, INFO_AGV WHERE EEC_ETAT = @EVNT_ENATTENTE AND IAG_ID = EEC_AGV
		AND IAG_OPERATIONNEL = 'O' ORDER BY IAG_DECHARGE DESC
	-- Ouverture et parcours du curseur
	open c_newEvent
	fetch next from c_newEvent into @vc_idEvt, @vc_idAgv, @vc_typeAct
	while (@@FETCH_STATUS = 0)
	begin
		SET @v_coe_id_1 = NULL
		set @v_idMission = NULL
		if @vc_typeAct IN (@TYPE_CHANGEMENT_BATTERIE, @TYPE_ENTREE_CHARGE_PLAN, @TYPE_ENTREE_CHARGE_AUTO)
		begin
			-- Récupération de la fonction de recherche spécifique d'adresse d'énergie
			SELECT @v_par_valeur = CASE PAR_VAL WHEN '' THEN NULL ELSE PAR_VAL END FROM PARAMETRE WHERE PAR_NOM = 'OBJET_ENERGIE'
			IF (@v_par_valeur IS NOT NULL)
			BEGIN
				EXEC @v_coe_id_1 = @v_par_valeur @vc_idAgv, @vc_typeAct
				SELECT TOP 1 @v_coe_type = COE_TYPE, @v_coe_rack = COE_RACK, @v_tac_idsystemeexecution_1 = COE_ADRSYS, @v_tac_idbaseexecution_1 = COE_ADRBASE,
					@v_tac_idsousbaseexecution_1 = COE_ADRSSBASE, @v_tac_affinage_1 = CASE BAS_TYPE WHEN 0 THEN @AFFI_ATTRIBUTION ELSE @AFFI_AUCUN END
					FROM CONFIG_OBJ_ENERGIE LEFT OUTER JOIN BASE ON BAS_SYSTEME = COE_ADRSYS AND BAS_BASE = COE_ADRBASE
					WHERE COE_ID = @v_coe_id_1
			END
			ELSE
				-- recherche poste de changement de batterie libre
				SELECT TOP 1 @v_coe_id_1 = COE_ID, @v_coe_type = COE_TYPE, @v_coe_rack = COE_RACK, @v_tac_idsystemeexecution_1 = COE_ADRSYS, @v_tac_idbaseexecution_1 = COE_ADRBASE,
					@v_tac_idsousbaseexecution_1 = COE_ADRSSBASE, @v_tac_affinage_1 = CASE BAS_TYPE WHEN 0 THEN @AFFI_ATTRIBUTION ELSE @AFFI_AUCUN END
					FROM CONFIG_RSV_ENERGIE INNER JOIN CONFIG_OBJ_ENERGIE ON CRE_IDOBJ = COE_ID
					INNER JOIN ADRESSE ON ADR_SYSTEME = COE_ADRSYS AND ADR_BASE = COE_ADRBASE AND ADR_SOUSBASE = COE_ADRSSBASE
					INNER JOIN BASE ON BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE
					WHERE CRE_IDAGV = @vc_idAgv AND COE_ENSERVICE = 1
					AND ((COE_TYPE IN (@TYPE_CHANGEMENT_BATTERIE_MANUEL, @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_NAVETTE, @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME) AND @vc_typeAct = @TYPE_CHANGEMENT_BATTERIE)
					OR (COE_TYPE = @TYPE_RECHARGE_BATTERIE AND @vc_typeAct IN (@TYPE_ENTREE_CHARGE_PLAN, @TYPE_ENTREE_CHARGE_AUTO)))
					AND ((COE_TYPE IN (@TYPE_CHANGEMENT_BATTERIE_MANUEL, @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_NAVETTE) AND COE_MAXACCU > (SELECT COUNT(*) FROM INFO_AGV WHERE IAG_ID <> @vc_idAgv AND ((IAG_BASE_DEST = ADR_BASE
						AND NOT EXISTS (SELECT 1 FROM MISSION, TACHE WHERE MIS_IDAGV = IAG_ID AND MIS_IDETAT NOT IN (@ETAT_ANNULE, @ETAT_TERMINE) AND TAC_IDMISSION = MIS_IDMISSION
						AND TAC_IDADRSYS = ADR_SYSTEME AND TAC_IDADRBASE = ADR_BASE))
						OR (IAG_OPERATIONNEL = 'O' AND EXISTS (SELECT 1 FROM MISSION, TACHE WHERE MIS_IDAGV = IAG_ID AND MIS_IDETAT NOT IN (@ETAT_ANNULE, @ETAT_TERMINE) AND TAC_IDMISSION = MIS_IDMISSION
						AND TAC_IDADRSYS = ADR_SYSTEME AND TAC_IDADRBASE = ADR_BASE)))))
					OR (COE_TYPE IN (@TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME, @TYPE_RECHARGE_BATTERIE)))
					ORDER BY CASE COE_TYPE WHEN @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME THEN CASE WHEN EXISTS (SELECT 1 FROM BATTERIE WHERE BAT_CONFIG_OBJ_ENERGIE = COE_ID) THEN 1 ELSE NULL END ELSE NULL END					
			IF @v_coe_id_1 IS NOT NULL
			BEGIN
				IF @v_coe_type = @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME
				BEGIN
					SELECT TOP 1 @v_coe_id_2 = COE_ID, @v_tac_idsystemeexecution_2 = COE_ADRSYS, @v_tac_idbaseexecution_2 = COE_ADRBASE,
						@v_tac_idsousbaseexecution_2 = COE_ADRSSBASE, @v_tac_affinage_2 = CASE BAS_TYPE WHEN 0 THEN @AFFI_ATTRIBUTION ELSE @AFFI_AUCUN END
						FROM CONFIG_RSV_ENERGIE INNER JOIN CONFIG_OBJ_ENERGIE ON CRE_IDOBJ = COE_ID
						INNER JOIN ADRESSE ON ADR_SYSTEME = COE_ADRSYS AND ADR_BASE = COE_ADRBASE AND ADR_SOUSBASE = COE_ADRSSBASE
						INNER JOIN BASE ON BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE
						WHERE CRE_IDAGV = @vc_idAgv AND COE_ID <> @v_coe_id_1 AND COE_ENSERVICE = 1 AND COE_TYPE = @v_coe_type AND COE_RACK = @v_coe_rack
					IF @v_coe_id_2 IS NOT NULL
					BEGIN
						EXEC @v_status = INT_CREATEMISSION @v_mis_idmission = @v_idMission out, @v_mis_idagv = @vc_idAgv
						SET @v_error = @@ERROR
						IF @v_status = @CODE_OK AND @v_error = 0
						BEGIN
							SET @v_ata_idaction = @ACTI_DEPOSE_BATTERIE
							EXEC @v_status = INT_ADDTACHEMISSION @v_tac_idtache = @v_tac_idtache out, @v_tac_idmission = @v_idMission, @v_tac_affinage = @v_tac_affinage_1,
								@v_tac_idsystemeexecution = @v_tac_idsystemeexecution_1, @v_tac_idbaseexecution = @v_tac_idbaseexecution_1, @v_tac_idsousbaseexecution = @v_tac_idsousbaseexecution_1,
								@v_tac_idaction = @v_ata_idaction
							SET @v_error = @@ERROR
							IF @v_status = @CODE_OK AND @v_error = 0
							BEGIN
								SET @v_ata_idaction = @ACTI_PRISE_BATTERIE
								EXEC @v_status = INT_ADDTACHEMISSION @v_tac_idtache = @v_tac_idtache out, @v_tac_idmission = @v_idMission, @v_tac_affinage = @v_tac_affinage_2,
									@v_tac_idsystemeexecution = @v_tac_idsystemeexecution_2, @v_tac_idbaseexecution = @v_tac_idbaseexecution_2, @v_tac_idsousbaseexecution = @v_tac_idsousbaseexecution_2,
									@v_tac_idaction = @v_ata_idaction
								SET @v_error = @@ERROR
							END
						END
					END
				END
				ELSE
				BEGIN
					SET @v_ata_idaction = CASE @v_coe_type WHEN @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_NAVETTE THEN @ACTI_CHANGEMENT_BATTERIE_AUTOMATIQUE
						WHEN @TYPE_CHANGEMENT_BATTERIE_MANUEL THEN @ACTI_CHANGEMENT_BATTERIE_MANUEL
						WHEN @TYPE_RECHARGE_BATTERIE THEN @ACTI_CHARGEMENT_BATTERIE_PLAN END
					IF @v_ata_idaction = @ACTI_CHARGEMENT_BATTERIE_PLAN AND @vc_typeAct = @TYPE_ENTREE_CHARGE_AUTO
						SET @v_ata_idaction = @ACTI_CHARGEMENT_BATTERIE_AUTO
					EXEC @v_status = INT_CREATEMISSION @v_mis_idmission = @v_idMission out, @v_mis_idagv = @vc_idAgv
					SET @v_error = @@ERROR
					IF @v_status = @CODE_OK AND @v_error = 0
					BEGIN
						EXEC @v_status = INT_ADDTACHEMISSION @v_tac_idtache = @v_tac_idtache out, @v_tac_idmission = @v_idMission, @v_tac_affinage = @v_tac_affinage_1,
							@v_tac_idsystemeexecution = @v_tac_idsystemeexecution_1, @v_tac_idbaseexecution = @v_tac_idbaseexecution_1, @v_tac_idsousbaseexecution = @v_tac_idsousbaseexecution_1,
							@v_tac_idaction = @v_ata_idaction
						SET @v_error = @@ERROR
					END
				END
				IF @v_status = @CODE_OK AND @v_error = 0
				BEGIN
					update EVT_ENERGIE_EN_COURS set EEC_ETAT = @EVNT_ENCOURS, EEC_IDMISSION = @v_idMission, EEC_IDOBJ = @v_coe_id_1
						where EEC_ID = @vc_idEvt
					SET @v_error = @@ERROR
					IF @v_error = 0
						SET @v_retour = @CODE_OK
				END
				ELSE
					SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
			END
		END
		ELSE if @vc_typeAct = @TYPE_SORTIE_CHARGE
		begin
			-- declenchement sortie charge sur agv
			update INFO_AGV set IAG_ENCHARGE = 0, IAG_HORODATE_ENERGIE = GETDATE(), IAG_DECHARGE = 0 where IAG_ID = @vc_idAgv 
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				update EVT_ENERGIE_EN_COURS set EEC_ETAT = @EVNT_TERMINE where EEC_ID = @vc_idEvt
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					set @v_reveilAGV = 1
					SET @v_retour = @CODE_OK
				END
			END
		END
		fetch next from c_newEvent into @vc_idEvt,@vc_idAgv,@vc_typeAct
	end
	-- destruction du curseur
	close c_newEvent
	deallocate c_newEvent
	IF @v_retour <> @CODE_OK
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_retour



