SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Procedure		: SPV_EXECUTEORDRE
-- Paramètre d'entrée	: @v_idOrdre : Identifiant de l'ordre Agv à exécuter
--						  @v_ofsProfondeur : Offset de profondeur
--						  @v_ofsNiveau : Offset de niveau
--						  @v_ofsColonne : Offset de colonne
--						  @v_ofsEngagement : Offset d'engagement
--			  @v_nbDetail : Nombre de tâche de l'ordre
--			  @v_lstDetail : Chaîne de caractères listant le détail de l'ordre :
--			  Pour chaque tâche : [idcharge;statut primaire;adrsys;adrBase;adrSsBase;
--			  orientation;nbActionSecondaire;listeActionSecondaire;]
--			  Pour chaque action secondaire : [idAction;statut secondaire;résultat;description;]
--			  La liste est dimensionnée pour avoir 10 détails au maximum
--			  @v_statutGeneral : Statut général d'exécution de l'ordre
--			  @v_descriptionGeneral : Description général d'exécution de l'ordre
-- Paramètre de sortie	: Code de retour par défaut :
--				- @CODE_OK : L'exécution de l'ordre est correcte.
--				- @CODE_KO_SQL : Une erreur s'est produite lors de l'exécution. 
--			        - @CODE_KO_INCONNU : L'ordre est inconnu
--				- @CODE_KO_INATTENDU : Le nombre de détails du compte-rendu
--				d'exécution ne correspond pas au nombre de tâches de l'ordre.
--				- @CODE_KO_PLEIN : Un des emplacement de dépose est déjà plein 
--				- @CODE_KO_INEXISTANT : Une des charges de l'ordre n'existe pas
--				- @CODE_KO_ADR_INCONNUE : Une des adresses de l'ordre n'existe pas
--				- @CODE_KO_INTERDIT : Un des emplacements est interdit en prise ou dépose
--				- @CODE_KO_PARAM : Une des adresses de prise fournies n'est pas l'adresse de la charge
--				- @CODE_KO_INCOMPATIBLE : Les caracteristiques d'une des charges déposée sont incompatibles
--				avec l'emplacement de dépose
--			  @v_affichageCharge : Indique si l'affichage des informations liées aux charges
--			  sur l'AGV est à mettre à jour
--			  @v_ordreSuivant : Indique si suite au traitement du compte-rendu,
--			  un ordre suivant peut être émis vers l'AGV
-- Descriptif		: Cette procédure exécute un ordre agv suite au compte-rendu
--			  d'exécution du pilotage.
--			  réalise le transfert de charge (si elle existe) 
--			  puis vérifie la validité des ordres suivants.
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_EXECUTEORDRE]
	@v_idOrdre integer,
	@v_ofsProfondeur integer,
	@v_ofsNiveau integer,
	@v_ofsColonne integer,
	@v_ofsEngagement integer,
	@v_nbDetail integer,
	@v_lstDetail varchar(8000),
	@v_statutGeneral tinyint,
	@v_descriptionGeneral tinyint,
	@v_affichageCharge bit out,
	@v_ordreSuivant bit out
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
	@v_retour int,
	@v_idAgv tinyint,
	@v_idxTache integer,
	@v_idxActionSecondaire integer,
	@v_strTmp varchar(8000),
	@v_chg_idchargeDetail int,
	@v_chg_longueur smallint,
	@v_chg_offsetprofondeur int,
	@v_chg_offsetniveau int,
	@v_chg_offsetcolonne int,
	@v_statutPrimaire varchar(2),
	@v_adrSysDetail bigint,
	@v_adrBaseDetail bigint,
	@v_adrSsBaseDetail bigint,
	@v_orientationDetail smallint,
	@v_adrSys bigint,
	@v_adrBase bigint,
	@v_adrSsBase bigint,
	@v_pos integer,
	@v_newEtatTache tinyint,
	@v_newEtatOrdre tinyint,
	@v_idOrdreSuiv integer,
	@v_position_Ordre integer,
	@v_position_OrdreSuiv integer,
	@v_idTache int,
	@v_idMission integer,
	@v_idEtatOrdre tinyint,
	@v_dscEtatTache tinyint,
	@v_dscEtatOrdre tinyint,
	@v_dscEtatAction tinyint,
	@v_uneExecutionPrimaireOK bit,
	@v_uneExecutionSecondaireKO bit,
	@v_chargeSurAgv bit,
	@v_typeMission tinyint,
	@v_bas_type_magasin tinyint,
	@v_bas_accumulation bit,
	@v_bas_emplacement bit,
	@v_mag_idmagasin smallint,
	@v_ata_idaction int,
	@v_nbActionSecondaire int,
	@v_idAction int,
	@v_statutSecondaire tinyint,
	@v_resultat varchar(32),
	@v_validation bit,
	@v_ata_idoptionaction tinyint,
	@v_position tinyint,
	@v_bat_id tinyint,
	@v_accesbase bit,
	@v_emb_engagement smallint,
	@v_delta smallint,
	@v_tag_idtypeagv tinyint,
	@v_tag_fourche smallint

-- Déclaration des constantes de types d'actions
DECLARE
	@ACTI_PRIMAIRE bit

-- Déclaration des constantes d'actions
DECLARE
	@ACTI_PRISE int,
	@ACTI_DEPOSE int,
	@ACTI_VIDANGE int,
	@ACTI_DEPOSE_BATTERIE int,
	@ACTI_PRISE_BATTERIE int

-- Déclaration des constantes des états d'exécutions des actions
DECLARE
	@ACTION_OK tinyint,
	@ACTION_KO tinyint

-- Déclaration des constantes d'état d'exécution
DECLARE
	@ORDRE_OK tinyint,
	@ORDRE_KOACTION tinyint, -- erreur lors de l'exécution de l'action
	@ORDRE_KOMVT tinyint -- erreur lors de l'exécution du mouvement

-- Déclaration des constantes des états tâches
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_ENCOURS tinyint,
	@ETAT_STOPPE tinyint,
	@ETAT_SUSPENDU tinyint,
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint

-- Déclaration des constantes des détails état ordre Agv et tâche
DECLARE
	@ERREUR_MVT tinyint,
	@ERREUR_ACTION tinyint,
	@ERREUR_ACTIONPRIMAIRE tinyint,
	@ERREUR_ACTIONSECONDAIRE tinyint,
	@FIN_INTEGRAL tinyint,
	@FIN_PARTIEL tinyint,
	@INDEFINI tinyint,
	@EXECUTION_AUTOMATIQUE tinyint,
	@EXECUTION_MANUELLE tinyint,
	@DESC_ORDRE_TC tinyint,
	@DESC_RELANCE_MISSION tinyint,
	@DESC_RELANCE_INTERNE tinyint

-- Déclaration des constantes types mission
DECLARE
	@TYPE_TRANSFERT_CHARGE tinyint,
	@TYPE_BATTERIE tinyint	

-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_AGV tinyint,
	@TYPE_INTERFACE	tinyint,
	@TYPE_STOCK tinyint,
	@TYPE_PREPARATION tinyint
	
-- Déclaration des constantes d'options
DECLARE
	@OPTI_TABLIER tinyint,
	@OPTI_CENTREE tinyint,
	@OPTI_FOURCHE tinyint
	
-- Déclaration des constantes de traces
DECLARE
	@TRAC_MONTEE tinyint

-- Déclaration des constantes de défauts
DECLARE
	@DEFA_FAUSSE_PRISE_CHARGE int,
	@DEFA_FAUSSE_PRISE_BATTERIE int,
	@DEFA_FAUSSE_DEPOSE_CHARGE int,
	@DEFA_FAUSSE_DEPOSE_BATTERIE int
	
-- Déclaration des constantes de types d'ordres
DECLARE
	@TYPE_MOUVEMENT bit
	
-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INCONNU tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_INATTENDU tinyint

-- Définition des constantes
	SET @ORDRE_OK=0
	SET @ORDRE_KOACTION = 1
	SET @ORDRE_KOMVT = 2
	SET @ETAT_ENATTENTE=1
	SET @ETAT_ENCOURS=2
	SET @ETAT_STOPPE=3
	SET @ETAT_SUSPENDU=4
	SET @ETAT_TERMINE=5
	SET @ETAT_ANNULE=6
	SET @ACTION_OK = 0
	SET @ACTION_KO = 1
	SET @CODE_OK=0
	SET @CODE_KO = 1
	SET @CODE_KO_INCONNU = 7
	SET @CODE_KO_SQL=13
	SET @CODE_KO_INATTENDU=16
	SET @ERREUR_ACTION = 1
	SET @ERREUR_ACTIONPRIMAIRE = 1
	SET @ERREUR_MVT =2
	SET @ERREUR_ACTIONSECONDAIRE = 14
	SET @FIN_INTEGRAL =3
	SET @FIN_PARTIEL =4
	SET @INDEFINI = 1
	SET @EXECUTION_AUTOMATIQUE = 3
	SET @EXECUTION_MANUELLE = 4
	SET @DESC_ORDRE_TC = 2
	SET @DESC_RELANCE_MISSION = 10
	SET @DESC_RELANCE_INTERNE = 11
	SET @TYPE_TRANSFERT_CHARGE = 1
	SET @TYPE_BATTERIE = 2
	SET @TYPE_AGV = 1
	SET @TYPE_INTERFACE = 2
	SET @TYPE_STOCK = 3
	SET @TYPE_PREPARATION = 4	
	SET @ACTI_PRIMAIRE = 0
	SET @ACTI_PRISE = 2
	SET @ACTI_DEPOSE = 4
	SET @ACTI_VIDANGE = 8192
	SET @ACTI_PRISE_BATTERIE = 16384
	SET @ACTI_DEPOSE_BATTERIE = 32768
	SET @OPTI_TABLIER = 0
	SET @OPTI_CENTREE = 1
	SET @OPTI_FOURCHE = 2
	SET @TRAC_MONTEE = 9
	SET @DEFA_FAUSSE_PRISE_CHARGE = 3
	SET @DEFA_FAUSSE_PRISE_BATTERIE = 4
	SET @DEFA_FAUSSE_DEPOSE_CHARGE = 5
	SET @DEFA_FAUSSE_DEPOSE_BATTERIE = 6
	SET @TYPE_MOUVEMENT = 0

-- Initialisation des variables
	SET @v_retour = @CODE_KO
	SET @v_error = @CODE_OK
	SET @v_affichageCharge = 0
	SET @v_ordreSuivant = 0

	-- Initialisation du boolean spécifiant si au moins une tâche a été exécutée correctement
	set @v_uneExecutionPrimaireOK=0

	-- Récupération de l'état de l'ordre exécuté
	select @v_idEtatOrdre=ORD_IdEtat,@v_idAgv=ORD_IdAgv,@v_position_Ordre=ORD_Position
		from ORDRE_AGV INNER JOIN INFO_AGV ON IAG_ID = ORD_IdAgv where ORD_IdOrdre=@v_idOrdre
	-- Vérification que l'état de l'ordre exécuté par le pilotage est bien en cours
	IF @v_idEtatOrdre = @ETAT_ENCOURS
	BEGIN
		SET @v_newEtatOrdre = @v_idEtatOrdre
		-- Récupération de l'action et de son option
		SELECT DISTINCT @v_ata_idaction = ATA_IDACTION, @v_ata_idoptionaction = ATA_OPTION_ACTION FROM TACHE, ASSOCIATION_TACHE_ACTION_TACHE
			WHERE TAC_IDORDRE = @v_idOrdre AND ATA_IDTACHE = TAC_IDTACHE AND ATA_IDTYPEACTION = @ACTI_PRIMAIRE
		-- Vérification si les actions sont liées aux charges
		IF EXISTS (SELECT 1 FROM TACHE, ASSOCIATION_TACHE_ACTION_TACHE, ACTION WHERE TAC_IDORDRE = @v_idOrdre AND ATA_IDTACHE = TAC_IDTACHE
			AND ACT_IDACTION = ATA_IDACTION AND ACT_CHARGE = 1)
			SET @v_affichageCharge = 1
		ELSE
			SET @v_affichageCharge = 0

		BEGIN TRANSACTION
		set @v_idxTache=0
		set @v_strTmp = @v_lstDetail
		------------------------------------------------------------------------------------
		--              TRAITEMENT DES TACHES DE L'ORDRE EXECUTE
		------------------------------------------------------------------------------------
		while ((@v_idxTache < @v_nbDetail) AND (@v_error = @CODE_OK))
		begin
			SET @v_chg_idchargeDetail = 0
			SET @v_idMission = NULL
			-- RECUPERATION DES INFORMATIONS envoyées par le PILOTAGE pour chaque TACHE de l'ORDRE  
			set @v_pos = charindex(';',@v_strTmp)
			if (@v_pos <> 0)
			begin
				-- Récupération de la charge (envoyé par le pilotage)
				set @v_chg_idchargeDetail = substring(@v_strTmp,1,@v_pos-1)
				set @v_strTmp = substring(@v_strTmp,@v_pos+1,len(@v_strTmp)-@v_pos)
				set @v_pos = charindex(';',@v_strTmp)
				if (@v_pos <> 0)
				begin
					-- Récupération du statut primaire (envoyé par le pilotage)
					set @v_statutPrimaire = substring(@v_strTmp,1,@v_pos-1)
					set @v_strTmp = substring(@v_strTmp,@v_pos+1,len(@v_strTmp)-@v_pos)
					set @v_pos = charindex(';',@v_strTmp)
					if (@v_pos <> 0)
					begin
						-- Récupération de l'adresse système finale une fois l'action réalisée (envoyé par le pilotage)
						set @v_adrSysDetail = convert(bigint,substring(@v_strTmp,1,@v_pos-1))
						set @v_strTmp = substring(@v_strTmp,@v_pos+1,len(@v_strTmp)-@v_pos)
						set @v_pos = charindex(';',@v_strTmp)
						if (@v_pos <> 0)
						begin
							-- Récupération de l'adresse base finale une fois l'action réalisée (envoyé par le pilotage) 
							set @v_adrBaseDetail = convert(bigint,substring(@v_strTmp,1,@v_pos-1))
							set @v_strTmp = substring(@v_strTmp,@v_pos+1,len(@v_strTmp)-@v_pos)
							set @v_pos = charindex(';',@v_strTmp)
							if (@v_pos <> 0)
							begin
								-- Récupération de l'adresse sous base finale une fois l'action réalisée (envoyé par le pilotage)
								set @v_adrSsBaseDetail = convert(bigint,substring(@v_strTmp,1,@v_pos-1))
								set @v_strTmp = substring(@v_strTmp,@v_pos+1,len(@v_strTmp)-@v_pos)
								set @v_pos = charindex(';',@v_strTmp)
								if (@v_pos <> 0)
								begin
									-- Récupération de l'orientation de la charge une fois l'action réalisée (envoyé par le pilotage)
									set @v_orientationDetail = convert(int,substring(@v_strTmp,1,@v_pos-1))
									set @v_strTmp = substring(@v_strTmp,@v_pos+1,len(@v_strTmp)-@v_pos)

                   					-- Récupération de l'identifiant de la tâche et de l'action primaire s'il s'agit d'une tâche 
									-- liée à une charge 
									if  (@v_chg_idchargeDetail = 0)
									begin
										SELECT TOP 1 @v_idTache = TAC_IDTACHE, @v_typeMission=MIS_TypeMission, @v_adrSys = TAC_IDADRSYS, @v_adrBase = TAC_IDADRBASE, @v_adrSsBase = TAC_IDADRSSBASE
											FROM TACHE, MISSION WHERE TAC_IdOrdre = @v_idOrdre AND MIS_IdMission = TAC_IdMission
									end
									else
									begin
										select @v_idTache = TAC_IDTACHE, @v_IdMission = TAC_IdMission, @v_accesbase = TAC_ACCES_BASE,
											@v_typeMission=MIS_TypeMission, @v_bas_type_magasin = BAS_TYPE_MAGASIN, @v_mag_idmagasin = BAS_MAGASIN, @v_bas_accumulation = BAS_ACCUMULATION, @v_bas_emplacement = BAS_EMPLACEMENT,
											@v_chg_offsetprofondeur = CHG_POSY, @v_chg_offsetniveau = CHG_POSZ, @v_chg_offsetcolonne = CHG_POSX, @v_emb_engagement = EMB_ENGAGEMENT
											from TACHE, MISSION, CHARGE LEFT OUTER JOIN ADRESSE ON ADR_SYSTEME = CHG_Adr_KeySys and ADR_BASE = CHG_Adr_KeyBase and ADR_SOUSBASE = CHG_Adr_KeySsBase
											LEFT OUTER JOIN BASE ON BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE LEFT OUTER JOIN EMBALLAGE ON EMB_ID = CHG_EMBALLAGE
											where TAC_IdOrdre=@v_IdOrdre and MIS_IdMission=TAC_IdMission
											and MIS_IdCharge=@v_chg_idchargeDetail AND CHG_ID = MIS_IdCharge
									end
									-- Si une des tâches du compte-rendu d'exécution du pilotage Agv n'est pas une des tâches de l'ordre Agv
									-- => On rejette le compte-rendu d'exécution
									if (@v_idTache is null)
									begin
										set @v_error = @CODE_KO_INATTENDU
										break
									end
									else
									begin
										SET @v_uneExecutionSecondaireKO = 0
										SET @v_dscEtatAction = @INDEFINI
										-- Traitement des actions secondaires
										set @v_pos = charindex(';', @v_strTmp)
										if @v_pos <> 0
										begin
											-- Récupération du nombre d'actions secondaires
											set @v_nbActionSecondaire = convert(int, substring(@v_strTmp, 1, @v_pos - 1))
											set @v_strTmp = substring(@v_strTmp, @v_pos + 1, len(@v_strTmp) - @v_pos)
											if @v_nbActionSecondaire <> 0
											begin
												set @v_idxActionSecondaire = @v_nbActionSecondaire
												while @v_idxActionSecondaire > 0
												begin
													set @v_pos = charindex(';', @v_strTmp)
													if @v_pos <> 0
													begin
														-- Récupération de l'identifiant de l'action secondaire (renvoyé par le pilotage)
														set @v_idAction = convert(int, substring(@v_strTmp, 1, @v_pos - 1))
														set @v_strTmp = substring(@v_strTmp, @v_pos + 1, len(@v_strTmp) - @v_pos)
														set @v_pos = charindex(';', @v_strTmp)
														if @v_pos <> 0
														begin
															-- Récupération du statut secondaire (envoyé par le pilotage)
															set @v_statutSecondaire = convert(tinyint, substring(@v_strTmp, 1, @v_pos - 1))
															set @v_strTmp = substring(@v_strTmp, @v_pos + 1, len(@v_strTmp) - @v_pos)
															set @v_pos = charindex(';', @v_strTmp)
															if @v_pos <> 0
															begin
																-- Récupération du résultat de l'action secondaire (envoyé par le pilotage)
																set @v_resultat = substring(@v_strTmp, 1, @v_pos - 1)
																set @v_strTmp = substring(@v_strTmp, @v_pos + 1, len(@v_strTmp) - @v_pos)
																set @v_pos = charindex(';', @v_strTmp)
																if @v_pos <> 0
																begin
																	-- Récupération de la description (envoyé par le pilotage)
																	set @v_dscEtatAction = convert(tinyint, substring(@v_strTmp, 1, @v_pos - 1))
																	set @v_strTmp = substring(@v_strTmp, @v_pos + 1, len(@v_strTmp) - @v_pos)
																	if (convert(int, @v_statutPrimaire) = @ORDRE_OK)
																	begin
																		EXEC @v_error = SPV_VALUATIONCHARGE @v_chg_idchargeDetail, @v_idAction, @v_statutSecondaire out, @v_resultat, @v_dscEtatAction out, @v_validation out
																		if (@v_error <> @CODE_OK)
																			break
																		else
																		begin
																			if @v_statutSecondaire = @ACTION_KO
																				SET @v_uneExecutionSecondaireKO = 1
																			-- Mise à jour de la table ASSOCIATION_TACHE_ACTION_TACHE
																			update ASSOCIATION_TACHE_ACTION_TACHE set ATA_IdEtat = @v_statutSecondaire, ATA_Resultat = @v_resultat,
																				ATA_DESC_ETAT_ACTION = @v_dscEtatAction, ATA_VALIDATION = @v_validation
																				WHERE ATA_IdAction = @v_idAction AND ((@v_idMission IS NOT NULL AND ATA_IDTACHE = @v_idTache)
																					OR (@v_idMission IS NULL AND ATA_IDTACHE IN (SELECT TAC_IDTACHE FROM TACHE WHERE TAC_IDORDRE = @v_idOrdre)))
																			if @@ERROR <> 0
																			begin
																				set @v_error = @CODE_KO_SQL
																				break
																			end
																		end
																	end
																end
															end
														end
													end
													set @v_idxActionSecondaire = @v_idxActionSecondaire - 1
												end
												if @v_error <> @CODE_OK
													break
											end
										end
									end
									-- TRAITEMENT DES INFORMATIONS envoyées par le PILOTAGE pour chaque TACHE de l'ORDRE
									if (convert(int,@v_statutPrimaire) = @ORDRE_OK)
									begin
										-- La tâche s'est exécutée correctement, elle passe dans l'état terminé
										set @v_newEtatTache=@ETAT_TERMINE
										if @v_uneExecutionSecondaireKO = 0
											set @v_dscEtatTache = CASE @v_descriptionGeneral WHEN @DESC_ORDRE_TC THEN @EXECUTION_MANUELLE ELSE @EXECUTION_AUTOMATIQUE END
										else
											set @v_dscEtatTache=@ERREUR_ACTIONSECONDAIRE
										set @v_uneExecutionPrimaireOK=1
										-- Mise à jour de l'adresse de la charge s'il s'agit d'une action de transfert charge
										if (@v_ata_idaction = @ACTI_PRISE) or (@v_ata_idaction = @ACTI_DEPOSE)
										begin
											SET @v_position = CASE @v_ata_idaction WHEN @ACTI_PRISE THEN @v_ata_idoptionaction ELSE NULL END
											SELECT @v_chg_longueur = LONGUEUR FROM CHARGE OUTER APPLY dbo.SPV_DIMENSIONCHARGE(CHG_HAUTEUR, CHG_LARGEUR, CHG_LONGUEUR, CHG_FACE, CHG_GABARIT, CHG_EMBALLAGE)
												WHERE CHG_ID = @v_chg_idchargeDetail
											SELECT @v_tag_idtypeagv = IAG_TYPE, @v_tag_fourche = TAG_FOURCHE FROM INFO_AGV, TYPE_AGV WHERE IAG_ID = @v_idAgv AND TAG_ID = IAG_TYPE AND TAG_TYPE_OUTIL IN (1, 2)
											IF ((@v_ata_idaction = @ACTI_PRISE AND @v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_bas_accumulation = 1) OR 
												(@v_ata_idaction = @ACTI_DEPOSE AND EXISTS (SELECT 1 FROM ADRESSE, BASE WHERE ADR_SYSTEME = @v_adrSysDetail AND ADR_BASE = @v_adrBaseDetail AND ADR_SOUSBASE = @v_adrSsBaseDetail
												AND BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE AND BAS_TYPE_MAGASIN IN (@TYPE_STOCK, @TYPE_PREPARATION) AND BAS_ACCUMULATION = 1)))
											BEGIN
												IF @v_ata_idaction = @ACTI_PRISE
												BEGIN
													IF @v_bas_emplacement = 1
													BEGIN
														IF ISNULL(@v_accesbase, 0) = 0
															SET @v_chg_offsetprofondeur = @v_chg_offsetprofondeur - @v_ofsProfondeur
														ELSE
															SET @v_chg_offsetprofondeur = @v_ofsProfondeur - (@v_chg_offsetprofondeur + @v_chg_longueur)
													END
													ELSE
													BEGIN
														SET @v_chg_offsetprofondeur = 0
														IF @v_tag_fourche IS NOT NULL
														BEGIN
															IF @v_chg_longueur < @v_tag_fourche AND ISNULL(@v_position, @OPTI_TABLIER) IN (@OPTI_CENTREE, @OPTI_FOURCHE)
																SET @v_delta = CASE @v_position WHEN @OPTI_CENTREE THEN (@v_tag_fourche - @v_chg_longueur) / 2
																WHEN @OPTI_FOURCHE THEN @v_tag_fourche - @v_chg_longueur END
															ELSE
																SET @v_delta = 0
															SET @v_chg_offsetprofondeur = @v_delta
														END
													END
												END
												ELSE
												BEGIN
													IF ISNULL(@v_accesbase, 0) = 0
														SET @v_chg_offsetprofondeur = @v_chg_offsetprofondeur + @v_ofsProfondeur
													ELSE
														SET @v_chg_offsetprofondeur = @v_ofsProfondeur - (@v_chg_offsetprofondeur + @v_chg_longueur)
													IF @v_tag_fourche IS NOT NULL
													BEGIN
														IF @v_chg_longueur < @v_tag_fourche AND ISNULL(@v_position, @OPTI_TABLIER) IN (@OPTI_CENTREE, @OPTI_FOURCHE)
															SET @v_delta = CASE @v_position WHEN @OPTI_CENTREE THEN (@v_tag_fourche - @v_chg_longueur) / 2
															WHEN @OPTI_FOURCHE THEN @v_tag_fourche - @v_chg_longueur END
														ELSE
															SET @v_delta = 0
														IF ISNULL(@v_accesbase, 0) = 0
															SET @v_chg_offsetprofondeur = @v_chg_offsetprofondeur + @v_delta
														ELSE
															SET @v_chg_offsetprofondeur = @v_chg_offsetprofondeur - @v_delta
													END
												END
												IF @v_ata_idaction = @ACTI_PRISE
													SET @v_chg_offsetniveau = @v_chg_offsetniveau - @v_ofsNiveau
												ELSE
													SET @v_chg_offsetniveau = @v_chg_offsetniveau + @v_ofsNiveau
												IF @v_ata_idaction = @ACTI_PRISE
													SET @v_chg_offsetcolonne = 0
												ELSE
													SET @v_chg_offsetcolonne = @v_ofsColonne
											END
											ELSE IF (@v_ata_idaction = @ACTI_PRISE AND ((@v_bas_type_magasin = @TYPE_STOCK AND @v_bas_accumulation = 0) OR (@v_bas_type_magasin = @TYPE_INTERFACE)))
											BEGIN
												IF @v_tag_fourche IS NOT NULL
												BEGIN
													IF @v_chg_longueur < @v_tag_fourche AND ISNULL(@v_position, @OPTI_TABLIER) IN (@OPTI_CENTREE, @OPTI_FOURCHE)
														SET @v_delta = CASE @v_position WHEN @OPTI_CENTREE THEN (@v_tag_fourche - @v_chg_longueur) / 2
														WHEN @OPTI_FOURCHE THEN @v_tag_fourche - @v_chg_longueur END
													ELSE
														SET @v_delta = 0
													SET @v_chg_offsetprofondeur = @v_chg_offsetprofondeur + @v_delta
												END
												ELSE
													SET @v_chg_offsetprofondeur = 0
												SET @v_chg_offsetniveau = 0
												SET @v_chg_offsetcolonne = 0
											END
											ELSE
											BEGIN
												SET @v_chg_offsetprofondeur = 0
												SET @v_chg_offsetniveau = @v_ofsNiveau
												SET @v_chg_offsetcolonne = @v_ofsColonne
											END
											-- On ne tient pas compte des interdictions d'emplacements
											-- On demande explicitement au gestionnaire de charge de ne pas contrôler
											-- l'adresse d'où l'on retire la charge
											EXEC @v_error = INT_TRANSFERCHARGE @v_tag_idtypeagv, @v_chg_idchargeDetail, @v_adrSysDetail, @v_adrBaseDetail, @v_adrSsBaseDetail, NULL,
												@v_accesbase, @v_orientationDetail, @v_chg_offsetprofondeur, @v_chg_offsetniveau, @v_chg_offsetcolonne, @v_position, 1, @v_idTache
											IF @v_error <> @CODE_OK
												BREAK
										end
										ELSE IF @v_ata_idaction = @ACTI_VIDANGE
										BEGIN
											EXEC @v_error = SPV_VIDANGECHARGE @v_chg_idchargeDetail
											IF @v_error <> @CODE_OK
												BREAK
										END
										ELSE IF @v_ata_idaction = @ACTI_DEPOSE_BATTERIE
										BEGIN
											SELECT TOP 1 @v_bat_id = BAT_ID FROM BATTERIE WHERE BAT_ID IN (2 * @v_idAgv - 1, 2 * @v_idAgv)
												ORDER BY BAT_INFO_AGV DESC, CASE WHEN BAT_CONFIG_OBJ_ENERGIE = (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_adrSys AND COE_ADRBASE = @v_adrBase AND COE_ADRSSBASE = @v_adrSsBase) THEN NULL ELSE BAT_CONFIG_OBJ_ENERGIE END
											EXEC @v_error = INT_TRANSFERBATTERIE @v_idAgv, @v_bat_id, @v_adrSys, @v_adrBase, @v_adrSsBase
											IF @v_error <> @CODE_OK
												BREAK
										END
										ELSE IF @v_ata_idaction = @ACTI_PRISE_BATTERIE
										BEGIN
											SELECT TOP 1 @v_bat_id = BAT_ID FROM BATTERIE WHERE BAT_ID IN (2 * @v_idAgv - 1, 2 * @v_idAgv)
												ORDER BY CASE WHEN BAT_CONFIG_OBJ_ENERGIE = (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_adrSys AND COE_ADRBASE = @v_adrBase AND COE_ADRSSBASE = @v_adrSsBase) THEN NULL ELSE BAT_CONFIG_OBJ_ENERGIE END
											EXEC @v_error = INT_TRANSFERBATTERIE @v_idAgv, @v_bat_id
											IF @v_error <> @CODE_OK
												BREAK
										END
									end
									else
									begin
										-- La tâche s'est exécutée avec une erreur
										-- Vérification si la charge est logiquement sur l'Agv
										if (@v_chg_idchargeDetail = 0)
											set @v_chargeSurAgv = 0
										else
										begin
											if ((@v_bas_type_magasin=@TYPE_AGV) and (@v_mag_idmagasin=@v_idAgv))
												set @v_chargeSurAgv = 1
											else
												set @v_chargeSurAgv = 0
										end 
										if (convert(int,@v_statutPrimaire) = @ORDRE_KOMVT)
										begin
											-- La tâche s'est exécutée avec une erreur MOUVEMENT
											SET @v_dscEtatTache = @ERREUR_MVT
											SET @v_newEtatTache = @ETAT_ANNULE
											IF @v_typeMission = @TYPE_TRANSFERT_CHARGE
												SET @v_newEtatTache = CASE @v_chargeSurAgv WHEN 1 THEN @ETAT_STOPPE ELSE @ETAT_ENATTENTE END
										end
										else
										begin
											-- La tâche s'est exécutée avec une erreur ACTION 
											SET @v_DscEtatTache = @ERREUR_ACTIONPRIMAIRE
											SET @v_newEtatTache = @ETAT_ANNULE
											IF @v_typeMission = @TYPE_TRANSFERT_CHARGE
												SET @v_newEtatTache = CASE @v_chargeSurAgv WHEN 1 THEN @ETAT_STOPPE ELSE @ETAT_SUSPENDU END
											ELSE IF @v_typeMission = @TYPE_BATTERIE
											BEGIN
												IF @v_ata_idaction = @ACTI_DEPOSE_BATTERIE
												BEGIN
													SET @v_newEtatTache = @ETAT_ENCOURS
													-- Inversion des bases des tâches de dépose batterie et prise batterie puis relance
													UPDATE A SET TAC_IDADRSYS = B.TAC_IDADRSYS, TAC_IDADRBASE = B.TAC_IDADRBASE, TAC_IDADRSSBASE = B.TAC_IDADRSSBASE
														FROM TACHE A INNER JOIN TACHE B ON B.TAC_IDTACHE <> A.TAC_IDTACHE AND B.TAC_IDMISSION = A.TAC_IDMISSION
														WHERE ((@v_idMission IS NOT NULL AND A.TAC_IDTACHE = @v_idTache) OR (@v_idMission IS NULL AND A.TAC_IDORDRE = @v_idOrdre))
													IF @@ERROR <> 0
													BEGIN
														SET @v_error = @CODE_KO_SQL
														BREAK
													END
													ELSE
													BEGIN
														UPDATE TACHE SET TAC_IDADRSYS = @v_adrSys, TAC_IDADRBASE = @v_adrBase, TAC_IDADRSSBASE = @v_adrSsBase
															WHERE TAC_IdTache <> @v_idTache AND ((@v_idMission IS NOT NULL AND TAC_IDMISSION = @v_idMission) OR (@v_idMission IS NULL AND TAC_IDMISSION = (SELECT TAC_IDMISSION FROM TACHE WHERE TAC_IDTACHE = @v_idTache)))
														IF @@ERROR <> 0
														BEGIN
															SET @v_error = @CODE_KO_SQL
															BREAK
														END
														ELSE
														BEGIN
															UPDATE ORDRE_AGV SET ORD_IDETAT = @ETAT_ENATTENTE, ORD_DSCETAT = @DESC_RELANCE_INTERNE, ORD_TYPE = @TYPE_MOUVEMENT
																WHERE ORD_IDORDRE = @v_idOrdre
															IF @@ERROR <> 0
															BEGIN
																SET @v_error = @CODE_KO_SQL
																BREAK
															END
														END
													END
												END
												ELSE IF @v_ata_idaction = @ACTI_PRISE_BATTERIE
													SET @v_newEtatTache = @ETAT_STOPPE
											END
											IF @v_ata_idaction IN(@ACTI_PRISE, @ACTI_PRISE_BATTERIE, @ACTI_DEPOSE, @ACTI_DEPOSE_BATTERIE)
												INSERT INTO TRACE_DEFAUT (TRD_DATE, TRD_TYPE_TRACE, TRD_INFO_AGV, TRD_DEFAUT, TRD_TYPE)
													SELECT GETDATE(), @TRAC_MONTEE, @v_idAgv, CASE @v_ata_idaction WHEN @ACTI_PRISE THEN @DEFA_FAUSSE_PRISE_CHARGE
														WHEN @ACTI_PRISE_BATTERIE THEN @DEFA_FAUSSE_PRISE_BATTERIE
														WHEN @ACTI_DEPOSE THEN @DEFA_FAUSSE_DEPOSE_CHARGE
														WHEN @ACTI_DEPOSE_BATTERIE THEN @DEFA_FAUSSE_DEPOSE_BATTERIE END, 0
										end
									end
									-- Mise à jour de la table ASSOCIATION_TACHE_ACTION_TACHE
									update ASSOCIATION_TACHE_ACTION_TACHE set ATA_IdEtat = case convert(int, @v_statutPrimaire) when @ORDRE_OK then @ACTION_OK else @ACTION_KO end, ATA_DESC_ETAT_ACTION = @INDEFINI
										WHERE ATA_IdAction = @v_ata_idaction AND ((@v_idMission IS NOT NULL AND ATA_IDTACHE = @v_idTache)
											OR (@v_idMission IS NULL AND ATA_IDTACHE IN (SELECT TAC_IDTACHE FROM TACHE WHERE TAC_IDORDRE = @v_idOrdre)))
									if @@ERROR <> 0
									begin
										set @v_error = @CODE_KO_SQL
										break
									end
									-- Dans le cas d'une tâche qui repasse en attente, les autres tâches terminées de la mission
									-- repasse également en attente
									IF @v_NewEtatTache = @ETAT_ENATTENTE
									BEGIN
										UPDATE TACHE SET TAC_IDETAT = @v_NewEtatTache, TAC_DSCETAT = @v_DscEtatTache
											WHERE TAC_IdTache <> @v_idTache AND ((@v_idMission IS NOT NULL AND TAC_IDMISSION = @v_idMission)
												OR (@v_idMission IS NULL AND TAC_IDORDRE = @v_idOrdre))
											AND TAC_IDETAT = @ETAT_TERMINE
										IF @@ERROR <> 0
										BEGIN
											SELECT @v_error = @CODE_KO_SQL
											BREAK
										END
									END
									-- Mise à jour de l'état de la tâche et de la mission puis suppression du rattachement à l'ordre Agv
									-- quand la tâche repasse dans l'état attente, suspendu ou annulé
									update TACHE set TAC_IDADRSSBASE = CASE WHEN @v_NewEtatTache = @ETAT_TERMINE AND @v_ata_idaction = @ACTI_DEPOSE THEN @v_adrSsBaseDetail ELSE TAC_IDADRSSBASE END,
										TAC_IdEtat = @v_NewEtatTache, TAC_DscEtat = @v_DscEtatTache,
										TAC_IdOrdre = case @v_NewEtatTache when @ETAT_STOPPE then @v_idOrdre when @ETAT_ENCOURS then @v_idOrdre else NULL end,
										TAC_OFSPROFONDEUR = @v_ofsProfondeur, TAC_OFSNIVEAU = @v_ofsNiveau, TAC_OFSCOLONNE = @v_ofsColonne
										WHERE ((@v_idMission IS NOT NULL AND TAC_IDTACHE = @v_idTache)
											OR (@v_idMission IS NULL AND TAC_IDORDRE = @v_idOrdre))
									if @@ERROR <> 0
									begin
										set @v_error = @CODE_KO_SQL
										break
									end
								end
							end
						end
					end
				end
			end
			set @v_idxTache = @v_idxTache+1
		end
		------------------------------------------------------------------------------------
		--              TRAITEMENT DE L'ORDRE EXECUTE
		------------------------------------------------------------------------------------
		-- Mise à jour de l'état de l'ordre exécuté
		if (@v_error = @CODE_OK)
		begin
			if (@v_statutGeneral = @ORDRE_OK)
			begin
				-- Toutes les tâches ont été exécutées correctement
				-- Vérification de tâches rattachées à l'ordre : cas d'un compte-rendu partiel
				if not exists (select 1 from TACHE where TAC_IdOrdre=@v_idOrdre)
				begin
					set @v_newEtatOrdre=@ETAT_TERMINE
					set @v_dscEtatOrdre=@FIN_INTEGRAL
				end
			end
			else
			begin
				-- Vérification de tâches rattachées à l'ordre : cas d'au moins une tâche exécutée avec erreur
				if exists (select 1 from TACHE where TAC_IdOrdre=@v_idOrdre)
				begin
					IF NOT EXISTS (SELECT 1 FROM TACHE WHERE TAC_IDORDRE = @v_idOrdre AND TAC_IDETAT = @ETAT_ENCOURS)
					BEGIN
						set @v_newEtatOrdre= @ETAT_STOPPE
						set @v_dscEtatOrdre=case @v_statutGeneral when @ORDRE_KOACTION then @ERREUR_ACTION else @ERREUR_MVT end
					END
				end
				else
				begin
					-- Si au moins une tâche a été exécutée correctement, on considère que l'ordre est terminé (partiellement)
					-- sinon il est annulé
					if (@v_uneExecutionPrimaireOK = 1)
					begin
						set @v_newEtatOrdre=@ETAT_TERMINE 
						set @v_dscEtatOrdre=@FIN_PARTIEL
					end
					else
					begin 
						set @v_newEtatOrdre= @ETAT_ANNULE  
						set @v_dscEtatOrdre=case @v_statutGeneral when @ORDRE_KOACTION then @ERREUR_ACTION else @ERREUR_MVT end
					end 
				end
			end
			-- Récupération de l'ordre suivant
			select TOP 1 @v_idOrdreSuiv=ORD_IdOrdre,@v_position_OrdreSuiv=ORD_Position from ORDRE_AGV
				where (ORD_Position>@v_position_Ordre)and(ORD_IdAgv=@v_idAgv) AND ORD_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE)
				order by ORD_Position
			IF @v_newEtatOrdre <> @v_idEtatOrdre
			BEGIN
				-- Mise à jour de l'état de l'ordre
				update ORDRE_AGV set ORD_IdEtat=@v_newEtatOrdre,ORD_DscEtat=@v_dscEtatOrdre
					where (ORD_IdOrdre=@v_idOrdre)
				if @@ERROR <> 0
					SELECT @v_error = @CODE_KO_SQL
			END
			IF ((@v_error = @CODE_OK) AND (@v_newEtatOrdre <> @ETAT_STOPPE) AND (@v_uneExecutionSecondaireKO = 0))
				SELECT @v_ordreSuivant = 1
		end
		------------------------------------------------------------------------------------
		--              TRAITEMENT DES ORDRES SUIVANTS
		------------------------------------------------------------------------------------
		if ((@v_error = @CODE_OK) AND (@v_newEtatOrdre <> @v_idEtatOrdre) AND (@v_statutGeneral <> @ORDRE_OK or @v_uneExecutionSecondaireKO = 1))
		begin
			if (@v_idOrdreSuiv is not NULL)
			begin
				-- si l'ordre exécuté est stoppé, il y a automatiquement interruption de l'activité agv
				IF @v_newEtatOrdre = @ETAT_STOPPE or @v_uneExecutionSecondaireKO = 1
					EXEC @v_error = SPV_REVISEORDRE @v_idOrdreSuiv, @v_idAgv, @v_position_OrdreSuiv, 1
				ELSE
					EXEC @v_error = SPV_REVISEORDRE @v_idOrdreSuiv, @v_idAgv, @v_position_OrdreSuiv, 0
			end
		end
		IF @v_error = @CODE_OK
			SELECT @v_retour = @CODE_OK
		ELSE
			SELECT @v_retour = @v_error
		if (@v_retour = @CODE_OK)
			COMMIT TRANSACTION
		else
			ROLLBACK TRANSACTION
	END
	ELSE
	BEGIN
		IF @v_idEtatOrdre IS NULL OR @v_idEtatOrdre = @ETAT_STOPPE
			SET @v_retour = @CODE_KO_INCONNU
		ELSE
			SET @v_retour = @CODE_KO_INATTENDU
	END
	RETURN @v_retour


